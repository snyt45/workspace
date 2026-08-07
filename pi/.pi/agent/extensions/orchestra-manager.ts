/**
 * orchestra-manager
 *
 * herdr のオーケストラグループ（同一タブ内のサブエージェント）を
 * グループ単位で表示・管理する拡張。
 *
 * ウィジェット表示:
 *   [review-npd] ⠹ reviewer ⠙ tester  ✓ done  ✓ done
 *   [fix-freeze] ✓ proofer
 *
 * コマンド:
 *   /orchestra                    → グループ一覧
 *   /orchestra close <tab-label>  → 指定グループの全paneを閉じる
 *   /orchestra close-all          → 全グループの全paneを閉じる
 *
 * 有効条件: HERDR_ENV=1 かつ ctx.mode === "tui"
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { exec, execSync } from "node:child_process";
import { promisify } from "node:util";

const execAsync = promisify(exec);

const POLL_INTERVAL_MS = 3000;
const HERDR_TIMEOUT_MS = 2500;
const WIDGET_KEY = "orchestra-manager";
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

interface HerdrTab {
  tab_id: string;
  label?: string;
}

interface OrchestraGroup {
  tabId: string;
  label: string;
  agents: HerdrAgent[];
}

function normalizeStatus(s: string | undefined): AgentStatus {
  switch (s) {
    case "working": case "idle": case "done": case "blocked": return s;
    default: return "unknown";
  }
}

function statusIcon(status: AgentStatus, frame: string, theme: any): string {
  switch (status) {
    case "working": return theme.fg("accent", frame);
    case "idle": return theme.fg("dim", "○");
    case "done": return theme.fg("success", "✓");
    case "blocked": return theme.fg("error", "⚠");
    default: return theme.fg("muted", "?");
  }
}

function groupStatus(agents: HerdrAgent[], frame: string, theme: any): string {
  const statuses = agents.map((a) => normalizeStatus(a.agent_status));
  if (statuses.every((s) => s === "done")) return theme.fg("success", "✓");
  if (statuses.some((s) => s === "blocked")) return theme.fg("error", "⚠");
  if (statuses.some((s) => s === "working")) return theme.fg("accent", frame);
  return theme.fg("dim", "○");
}

function renderWidget(groups: OrchestraGroup[], spinFrame: number, theme: any): string[] {
  const width = Math.max(40, (process.stdout?.columns ?? 80) - 2);
  const frame = SPIN_FRAMES[spinFrame % SPIN_FRAMES.length];
  const lines: string[] = [];

  for (const g of groups) {
    const gs = groupStatus(g.agents, frame, theme);
    const label = g.label || g.tabId.split(":")[1] || "untitled";
    const count = g.agents.length;
    const prefix = `${gs} ${theme.fg("accent", `[${label}]`)} ${theme.fg("dim", `(${count})`)}`;
    const remaining = width - visibleWidth(prefix);

    // Agent list: abbreviated per agent
    const agentParts: string[] = [];
    let used = 0;
    for (const a of g.agents) {
      const st = normalizeStatus(a.agent_status);
      const icon = statusIcon(st, frame, theme);
      const name = (a.name || a.agent).slice(0, 10);
      const part = `${icon}${theme.fg("text", name)}`;
      const pw = visibleWidth(part) + 1;
      if (used + pw > remaining && agentParts.length > 0) {
        agentParts.push(theme.fg("dim", `+${g.agents.length - agentParts.length}`));
        break;
      }
      agentParts.push(part);
      used += pw;
    }
    lines.push(prefix + " " + agentParts.join(" "));
  }
  return lines.length > 0 ? lines : [theme.fg("dim", "(no active orchestra)")];
}

function fireNotification(name: string, status: AgentStatus): void {
  const sound = status === "blocked" ? "request" : "done";
  exec(`herdr notification show ${JSON.stringify(name)} --sound ${sound}`, () => {});
}

export default function orchestraManager(pi: ExtensionAPI) {
  let enabled = true;
  let ctxRef: ExtensionContext | undefined;
  let pollTimer: ReturnType<typeof setInterval> | undefined;
  let spinFrame = 0;
  let groups: OrchestraGroup[] = [];
  // pane_id -> 前回 status。遷移検出用 (working→done/blocked)
  let prevState = new Map<string, AgentStatus>();

  function clearWidget() {
    try { ctxRef?.ui.setWidget(WIDGET_KEY, undefined); } catch {}
  }

  async function poll(): Promise<void> {
    if (!enabled || !ctxRef) return;
    try {
      const [agentResult, tabResult] = await Promise.all([
        execAsync("herdr agent list", { timeout: HERDR_TIMEOUT_MS }).then((r) => JSON.parse(r.stdout)),
        execAsync("herdr tab list", { timeout: HERDR_TIMEOUT_MS }).then((r) => JSON.parse(r.stdout)),
      ]);

      const workspaceId = process.env.HERDR_WORKSPACE_ID;
      const myPaneId = process.env.HERDR_PANE_ID;

      const agents: HerdrAgent[] = (agentResult?.result?.agents ?? []).filter(
        (a: HerdrAgent) => a.workspace_id === workspaceId && a.pane_id !== myPaneId,
      );

      const tabMap = new Map<string, string>(
        (tabResult?.result?.tabs ?? []).map((t: HerdrTab) => [t.tab_id, t.label ?? ""]),
      );

      // Group by tab_id
      const grouped = new Map<string, HerdrAgent[]>();
      for (const a of agents) {
        if (!a.tab_id) continue;
        const list = grouped.get(a.tab_id) ?? [];
        list.push(a);
        grouped.set(a.tab_id, list);
      }

      const myTabId = agents.find((a) => a.pane_id === myPaneId)?.tab_id;

      groups = Array.from(grouped.entries())
        .filter(([tabId]) => tabId !== myTabId) // exclude own tab
        .map(([tabId, ags]) => ({
          tabId,
          label: tabMap.get(tabId) ?? "",
          agents: ags,
        }))
        .sort((a, b) => (a.label || a.tabId).localeCompare(b.label || b.tabId));

      // Transition detection
      const nextState = new Map<string, AgentStatus>();
      for (const a of agents) {
        const st = normalizeStatus(a.agent_status);
        nextState.set(a.pane_id, st);
        const prev = prevState.get(a.pane_id);
        const name = (a.name || a.agent || a.pane_id);
        if (prev === "working" && (st === "done" || st === "blocked")) {
          fireNotification(name, st);
        }
      }
      prevState = nextState;

      render();
    } catch {
      // herdr not available or error
      if (enabled) clearWidget();
    }
  }

  function render(): void {
    if (!ctxRef || !enabled) return;
    const theme = (ctxRef as any).ui?.theme;
    if (!theme) return;
    if (groups.length === 0) {
      ctxRef.ui.setWidget(WIDGET_KEY, undefined);
      return;
    }
    const lines = renderWidget(groups, spinFrame, theme);
    ctxRef.ui.setWidget(WIDGET_KEY, lines);
  }

  function startPolling() {
    if (pollTimer) return;
    pollTimer = setInterval(() => {
      spinFrame = (spinFrame + 1) % SPIN_FRAMES.length;
      void poll();
    }, POLL_INTERVAL_MS);
    pollTimer.unref?.();
    // Immediate first poll
    void poll();
  }

  function stopPolling() {
    if (pollTimer) {
      clearInterval(pollTimer);
      pollTimer = undefined;
    }
    prevState.clear();
    groups = [];
    clearWidget();
  }

  /**
   * Close all agent panes in a group.
   * Uses `herdr pane close` for each pane individually.
   */
  function closeGroup(group: OrchestraGroup): { success: number; fail: number } {
    const myPaneId = process.env.HERDR_PANE_ID;
    let success = 0;
    let fail = 0;
    for (const a of group.agents) {
      if (a.pane_id === myPaneId) continue; // never close self
      try {
        execSync(`herdr pane close ${a.pane_id}`, { timeout: 3000, stdio: "pipe" });
        success++;
      } catch {
        fail++;
      }
    }
    return { success, fail };
  }

  function formatGroupList(): string {
    if (groups.length === 0) return "No active orchestras.";
    return groups
      .map((g) => {
        const label = g.label || g.tabId;
        const agents = g.agents
          .map((a) => `  ${a.agent_status.padEnd(8)} ${a.name || a.agent}`)
          .join("\n");
        return `[${label}] (${g.agents.length} agents)\n${agents}`;
      })
      .join("\n---\n");
  }

  pi.on("session_start", async (_event, ctx) => {
    if (process.env.HERDR_ENV !== "1" || ctx?.mode !== "tui") return;
    ctxRef = ctx;
    enabled = true;
    startPolling();
  });

  pi.on("session_shutdown", async () => {
    stopPolling();
  });

  pi.registerCommand("orchestra", {
    description: "Manage orchestra groups: list, close <label>, close-all",
    handler: async (args, ctx) => {
      const arg = (args ?? "").trim();
      const parts = arg.split(/\s+/);
      const sub = parts[0]?.toLowerCase();

      if (sub === "close" && parts.length >= 2) {
        const targetLabel = parts.slice(1).join(" ");
        const match = groups.find(
          (g) => g.label.toLowerCase() === targetLabel.toLowerCase() || g.tabId === targetLabel,
        );
        if (!match) {
          ctx.ui.notify(`Orchestra "${targetLabel}" not found.`, "error");
          ctx.ui.setEditorText(`Available:\n${formatGroupList()}`);
          return;
        }
        const ok = await ctx.ui.confirm(
          "Close orchestra?",
          `Close tab "${match.label || match.tabId}" with ${match.agents.length} agents?`,
        );
        if (!ok) return;
        const { success, fail } = closeGroup(match);
        const label = match.label || match.tabId;
        if (fail === 0) {
          ctx.ui.notify(`Closed ${success} panes: ${label}`, "info");
        } else {
          ctx.ui.notify(`Closed ${success}/${success + fail} panes: ${label}`, "warning");
        }
        return;
      }

      if (sub === "close-all") {
        if (groups.length === 0) {
          ctx.ui.notify("No active orchestras.", "info");
          return;
        }
        const ok = await ctx.ui.confirm(
          "Close all orchestras?",
          `Close ${groups.length} tab(s) with ${groups.reduce((s, g) => s + g.agents.length, 0)} agents?`,
        );
        if (!ok) return;
        let totalOk = 0;
        let totalFail = 0;
        for (const g of groups) {
          const { success, fail } = closeGroup(g);
          totalOk += success;
          totalFail += fail;
        }
        ctx.ui.notify(`Closed ${totalOk} panes${totalFail > 0 ? `, ${totalFail} failed` : ""}.`, "info");
        return;
      }

      // Default: show list
      ctx.ui.setEditorText(formatGroupList());
    },
  });
}
