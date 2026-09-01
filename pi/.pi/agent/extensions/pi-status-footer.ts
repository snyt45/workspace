/**
 * pi-status-footer
 *
 * Pi のフッターにモデル名・思考レベル・コンテキスト使用量を一行で表示。
 * pi-context-footer の代わりに使う。
 *
 *    [opencode/deepseek-v4-flash] [thinking: off] [████░░░░] 42% 84k/200k
 *
 * コマンド:
 *   /status-footer       → on/off トグル
 *   /status-footer on    → 表示
 *   /status-footer off   → 非表示
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

const BAR_WIDTH = 10;
const CHARS_PER_TOKEN = 4;

function estimateTokens(text: string): number {
  if (!text) return 0;
  return Math.max(1, Math.ceil(text.length / CHARS_PER_TOKEN));
}

function extractText(content: unknown): string {
  if (content == null) return "";
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";
  const parts: string[] = [];
  for (const c of content as Array<Record<string, unknown>>) {
    if (typeof c === "string") { parts.push(c); continue; }
    if (!c || typeof c !== "object") continue;
    if (typeof c.text === "string") parts.push(c.text);
    else if (typeof c.thinking === "string") parts.push(c.thinking);
  }
  return parts.join("\n");
}

function formatTokens(n: number | null): string {
  if (n == null) return "?";
  const abs = Math.abs(n);
  if (abs < 1000) return `${n}`;
  if (abs < 1_000_000) return `${(n / 1000).toFixed(n < 10000 ? 1 : 0)}k`;
  return `${(n / 1_000_000).toFixed(2)}M`;
}

function renderBar(percent: number | null, width: number, theme: any): string {
  const pct = Math.max(0, Math.min(100, percent ?? 0));
  const filled = Math.round((pct / 100) * width);
  const empty = Math.max(0, width - filled);
  const color = pct >= 85 ? "error" : pct >= 65 ? "warning" : "success";
  return theme.fg(color, "█".repeat(filled)) + theme.fg("dim", "░".repeat(empty));
}

export default function (pi: ExtensionAPI) {
  let enabled = true;
  let lastRealTokens: number | null = null;
  let contextWindow = 0;
  let lastPercent: number | null = null;
  let tidyMode = true;

  function buildStatusLines(ctx: ExtensionContext, theme: any, width: number): string[] {
    try {
      // モデル情報
      const model = ctx.model;
      const modelName = model?.id ?? "unknown";
      const provider = model?.provider ?? "?";
      const modelTag = `${provider}/${modelName}`;

      // 思考レベル
      let thinkingLevel = "off";
      try { thinkingLevel = pi.getThinkingLevel?.() ?? "off"; } catch {}

      // コンテキスト使用量
      try {
        const usage = ctx.getContextUsage?.();
        if (usage) {
          if (usage.tokens != null) lastRealTokens = usage.tokens;
          if (usage.contextWindow) contextWindow = usage.contextWindow;
          if (usage.percent != null) lastPercent = usage.percent;
        }
      } catch {}

      const bar = renderBar(lastPercent, BAR_WIDTH, theme);
      const pctStr = lastPercent != null ? `${lastPercent.toFixed(1)}%` : "?%";
      const tokStr = `${formatTokens(lastRealTokens)}/${formatTokens(contextWindow)}`;

      const usage = `${bar} ${theme.fg("text", pctStr)} ${theme.fg("dim", tokStr)}`;
      const modelPart = theme.fg("accent", `[${modelTag}]`);
      const thinkingPart = theme.fg("muted", `[thinking: ${thinkingLevel}]`);
      const pidTag = theme.fg("dim", `[pid ${process.pid}]`); // ponytail: ,PS のセッション一覧と目視で対応させるため

      // ponytail: 1行に収まれば1行、無理なら モデル/thinking と 使用量/pid の2行に分ける。さらに狭い場合は各行を … で切る
      const oneLine = [modelPart, thinkingPart, usage, pidTag].join(" ");
      const oneLineTruncated = truncateToWidth(oneLine, width, "…");
      if (oneLineTruncated === oneLine) return [oneLine];
      return [
        truncateToWidth([modelPart, thinkingPart].join(" "), width, "…"),
        truncateToWidth([usage, pidTag].join(" "), width, "…"),
      ];
    } catch {
      return [];
    }
  }

  function installFooter(ctx: ExtensionContext) {
    ctx.ui.setFooter((tui, theme, _footerData) => ({
      invalidate() {},
      render(width: number): string[] {
        try {
          if (!enabled) return [];
          void tui;
          const lines = buildStatusLines(ctx, theme, width);
          return lines.length ? lines : [theme.fg("dim", "status ?")];
        } catch {
          try { return [theme.fg("dim", "status ?")]; } catch { return ["status ?"]; }
        }
      },
      dispose: () => {},
    }));
  }

  pi.on("session_start", async (_event, ctx) => {
    if (enabled) installFooter(ctx);
  });

  pi.on("session_shutdown", () => {});

  pi.on("model_select", async (_event, ctx) => {
    // フッターは次の render で自動更新される
  });

  pi.on("thinking_level_select", async () => {
    // フッターは次の render で自動更新される
  });

  pi.registerCommand("status-footer", {
    description: "Toggle the status footer (model + thinking + context usage). on/off または トグル.",
    handler: async (args, ctx) => {
      const arg = (args ?? "").trim().toLowerCase();
      if (arg === "on") enabled = true;
      else if (arg === "off") enabled = false;
      else enabled = !enabled;

      if (enabled) installFooter(ctx);
      else ctx.ui.setFooter(undefined);

      ctx.ui.notify(`status-footer ${enabled ? "on" : "off"}`, "info");
    },
  });
}
