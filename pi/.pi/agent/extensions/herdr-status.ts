/**
 * herdr-status
 *
 * herdr の同一 workspace 内で動いている他のエージェント（サブエージェント）の状況を、
 * pi のエディタ上のウィジェットに常時表示する拡張。
 *
 *    ⠹ reviewer   dotfiles/1:p5  差分レビュー中
 *    ✓ runner     dotfiles/1:p7  テスト実行
 *    ⚠ proofer    dotfiles/1:p9  入力待ち
 *    +2 more
 *
 * 3秒間隔で `herdr agent list` を実行し、workspace_id で絞り込んで
 * 自分の pane は除外したものを一覧する。working 行は spinner でアニメ。
 * working→done / working→blocked の遷移で herdr の通知を鳴らす。
 *
 * コマンド:
 *   /herdr-status        → on/off トグル
 *   /herdr-status on     → 表示
 *   /herdr-status off    → 非表示・ポーリング停止
 *
 * 有効条件: HERDR_ENV=1 かつ ctx.mode === "tui"
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { exec } from "node:child_process";
import { promisify } from "node:util";

const execAsync = promisify(exec);

const POLL_INTERVAL_MS = 3000;
const RENDER_INTERVAL_MS = 120;
const HERDR_TIMEOUT_MS = 2500;
const WIDGET_KEY = "herdr-status";
const MAX_ROWS = 6;
const SPIN_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

type AgentStatus = "working" | "idle" | "done" | "blocked" | "unknown";

interface HerdrAgent {
  agent: string;
  agent_status: string;
  name?: string;
  pane_id: string;
  tab_id: string;
  workspace_id: string;
  terminal_title_stripped?: string;
}

interface HerdrWorkspace {
  workspace_id: string;
  label?: string;
}

interface HerdrTab {
  tab_id: string;
  label?: string;
}

function normalizeStatus(s: string | undefined): AgentStatus {
  switch (s) {
    case "working":
    case "idle":
    case "done":
    case "blocked":
      return s;
    default:
      return "unknown";
  }
}

function statusIcon(status: AgentStatus, frame: string, theme: any): string {
  switch (status) {
    case "working":
      return theme.fg("accent", frame);
    case "idle":
      return theme.fg("dim", "○");
    case "done":
      return theme.fg("success", "✓");
    case "blocked":
      return theme.fg("error", "⚠");
    default:
      return theme.fg("muted", "?");
  }
}

function statusLabel(status: AgentStatus): string {
  switch (status) {
    case "working": return "working";
    case "idle": return "idle";
    case "done": return "done";
    case "blocked": return "blocked";
    default: return "unknown";
  }
}

function availableWidth(): number {
  // ウィジェットは paddingX=1 の Text で描かれるので左右で 2 文字分消費する。
  const cols = (typeof process !== "undefined" && process.stdout?.columns) || 80;
  return Math.max(20, cols - 2);
}

// pane_id は "w21:p5"、tab_id は "w21:t1"。pane 名がないので
// workspace label + tab label + pane 番号（p5）で人間可読にする。
function paneLabel(
  agent: HerdrAgent,
  wsLabel: string | undefined,
  tabLabel: string | undefined,
): string {
  const paneNum = agent.pane_id?.split(":")[1] ?? "";
  const ws = wsLabel && wsLabel.length > 0 ? wsLabel : agent.workspace_id;
  const tab = tabLabel && tabLabel.length > 0 ? tabLabel : agent.tab_id?.split(":")[1] ?? "";
  return `${ws}/${tab}:${paneNum}`;
}

function buildLines(
  agents: HerdrAgent[],
  frame: string,
  wsLabels: Map<string, string>,
  tabLabels: Map<string, string>,
  theme: any,
): string[] {
  const width = availableWidth();
  const spacer = "  ";

  const rows = agents.map((a) => {
    const status = normalizeStatus(a.agent_status);
    const icon = statusIcon(status, frame, theme);
    const name = a.name && a.name.length > 0 ? a.name : a.agent;
    const pane = paneLabel(a, wsLabels.get(a.workspace_id), tabLabels.get(a.tab_id ?? ""));
    const prefix = `${icon}${spacer}${theme.fg("text", name)}${spacer}${theme.fg("dim", pane)}`;

    const remaining = width - visibleWidth(prefix);
    const title = a.terminal_title_stripped ?? "";
    let titlePart = "";
    if (remaining > 3 && title) {
      const truncated = truncateToWidth(title, remaining - 1, "…");
      titlePart = spacer + theme.fg("muted", truncated);
    }
    return prefix + titlePart;
  });

  if (rows.length > MAX_ROWS) {
    const shown = rows.slice(0, MAX_ROWS);
    shown.push(theme.fg("dim", `+${rows.length - MAX_ROWS} more`));
    return shown;
  }
  return rows;
}

function fireNotification(name: string, status: AgentStatus): void {
  const sound = status === "blocked" ? "request" : "done";
  const title = `${name}: ${statusLabel(status)}`;
  // 通知はベストエフォート。失敗は無視。
  exec(`herdr notification show ${JSON.stringify(title)} --sound ${sound}`, () => {});
}

export default function herdrStatusExtension(pi: ExtensionAPI) {
  let enabled = true;
  let inFlight = false;
  let ctxRef: ExtensionContext | undefined;
  let pollTimer: ReturnType<typeof setInterval> | undefined;
  let renderTimer: ReturnType<typeof setInterval> | undefined;
  let spinFrame = 0;
  // 最新の agent 一覧（poll で更新、render で参照）。
  let agents: HerdrAgent[] = [];
  let wsLabels = new Map<string, string>();
  let tabLabels = new Map<string, string>();
  // pane_id -> 前回の status。遷移検出用。
  let prevState = new Map<string, AgentStatus>();

  function clearWidget() {
    try {
      ctxRef?.ui.setWidget(WIDGET_KEY, undefined);
    } catch {}
  }

  async function poll(): Promise<void> {
    if (!enabled || inFlight || !ctxRef) return;
    inFlight = true;
    let agentsParsed: { result?: { agents?: HerdrAgent[] } } | undefined;
    let wsParsed: { result?: { workspaces?: HerdrWorkspace[] } } | undefined;
    let tabsParsed: { result?: { tabs?: HerdrTab[] } } | undefined;
    try {
      // 3本並列で取得。失敗時はウィジェットを消して静かにスキップ。
      [agentsParsed, wsParsed, tabsParsed] = await Promise.all([
        execAsync("herdr agent list", { timeout: HERDR_TIMEOUT_MS }).then((r) => JSON.parse(r.stdout)),
        execAsync("herdr workspace list", { timeout: HERDR_TIMEOUT_MS }).then((r) => JSON.parse(r.stdout)),
        execAsync("herdr tab list", { timeout: HERDR_TIMEOUT_MS }).then((r) => JSON.parse(r.stdout)),
      ]);
    } catch {
      clearWidget();
      return;
    } finally {
      inFlight = false;
    }

    // workspace_id / tab_id → label。
    wsLabels = new Map(
      (wsParsed?.result?.workspaces ?? []).map((w) => [w.workspace_id, w.label ?? ""]),
    );
    tabLabels = new Map(
      (tabsParsed?.result?.tabs ?? []).map((t) => [t.tab_id, t.label ?? ""]),
    );

    const workspaceId = process.env.HERDR_WORKSPACE_ID;
    const myPaneId = process.env.HERDR_PANE_ID;
    agents = (agentsParsed?.result?.agents ?? []).filter(
      (a) => a.workspace_id === workspaceId && a.pane_id !== myPaneId && !!a.tab_id,
    );

    // 遷移検出: working → done / working → blocked。
    const nextState = new Map<string, AgentStatus>();
    for (const a of agents) {
      const status = normalizeStatus(a.agent_status);
      nextState.set(a.pane_id, status);
      const prev = prevState.get(a.pane_id);
      const name = (a.name && a.name.length > 0 ? a.name : a.agent) ?? a.pane_id;
      if (prev === "working" && (status === "done" || status === "blocked")) {
        fireNotification(name, status);
      }
    }
    prevState = nextState;

    // 初回 poll 後、即座に1回描画。
    render();
  }

  function render(): void {
    if (!ctxRef) return;
    const theme = (ctxRef as any).ui?.theme;
    if (!theme) return;
    if (!enabled || agents.length === 0) {
      ctxRef.ui.setWidget(WIDGET_KEY, undefined);
      return;
    }
    const frame = SPIN_FRAMES[spinFrame % SPIN_FRAMES.length];
    const lines = buildLines(agents, frame, wsLabels, tabLabels, theme);
    ctxRef.ui.setWidget(WIDGET_KEY, lines);
  }

  function startPolling() {
    if (pollTimer && renderTimer) return;
    pollTimer = setInterval(() => {
      void poll();
    }, POLL_INTERVAL_MS);
    pollTimer.unref?.();
    renderTimer = setInterval(() => {
      spinFrame = (spinFrame + 1) % SPIN_FRAMES.length;
      render();
    }, RENDER_INTERVAL_MS);
    renderTimer.unref?.();
    void poll();
  }

  function stopPolling() {
    if (pollTimer) {
      clearInterval(pollTimer);
      pollTimer = undefined;
    }
    if (renderTimer) {
      clearInterval(renderTimer);
      renderTimer = undefined;
    }
    prevState.clear();
    agents = [];
    wsLabels.clear();
    tabLabels.clear();
  }

  pi.on("session_start", async (_event, ctx) => {
    // TUI のみ。headless モードではウィジェットを出せない。
    if (process.env.HERDR_ENV !== "1" || ctx?.mode !== "tui") {
      return;
    }
    ctxRef = ctx;
    enabled = true;
    startPolling();
  });

  pi.on("session_shutdown", async () => {
    stopPolling();
    clearWidget();
  });

  pi.registerCommand("herdr-status", {
    description:
      "Toggle the herdr agent status widget (same-workspace sub-agents). on/off または トグル.",
    handler: async (args, ctx) => {
      const arg = (args ?? "").trim().toLowerCase();
      if (arg === "on") enabled = true;
      else if (arg === "off") enabled = false;
      else enabled = !enabled;

      if (enabled) {
        ctxRef = ctx;
        startPolling();
        ctx.ui.notify(`herdr-status on`, "info");
      } else {
        stopPolling();
        clearWidget();
        ctx.ui.notify(`herdr-status off`, "info");
      }
    },
  });
}