/**
 * pi-tidy
 *
 * Pi の TUI を整理・トグル可能にする拡張機能。
 * tool 実行結果や thinking ブロックの表示を「必要なときだけ見える」状態に。
 *
 * 機能:
 *   - tidy モード: tool 出力を折りたたみ、thinking を簡潔ラベルに
 *   - detailed モード: 通常の Pi 表示
 *   - /tidy でモード切替
 *
 * 操作:
 *   /tidy           → モード切替 (tidy ↔ detailed)
 *   /tidy on        → tidy モード
 *   /tidy off       → detailed モード
 *   /tidy status    → 現在のモード表示
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

type TidyMode = "tidy" | "detailed";

const STORAGE_KEY = "pi-tidy:mode";

function loadMode(): TidyMode {
  try {
    // sessionManager の appendEntry で永続化も可能だが、
    // まずはシンプルにデフォルト tidy
    return "tidy";
  } catch {
    return "tidy";
  }
}

export default function (pi: ExtensionAPI) {
  let mode: TidyMode = loadMode();

  function applyMode(ctx: ExtensionContext) {
    try {
      if (mode === "tidy") {
        ctx.ui.setToolsExpanded(false);
        ctx.ui.setHiddenThinkingLabel("[🧠 thinking]");
      } else {
        ctx.ui.setToolsExpanded(true);
        ctx.ui.setHiddenThinkingLabel(undefined);
      }
      // pi-status-footer にモード変更を通知
      pi.events.emit("pi-tidy:mode", { mode: mode === "tidy" });
      ctx.ui.setStatus("tidy", mode === "tidy" ? "tidy" : undefined);
    } catch {
      // 安全のため
    }
  }

  // セッション開始時に適用
  pi.on("session_start", async (_event, ctx) => {
    applyMode(ctx);
  });

  // ターン開始時にも適用（ユーザーが手動で展開しても戻す）
  pi.on("turn_start", async (_event, ctx) => {
    if (mode === "tidy") {
      try { ctx.ui.setToolsExpanded(false); } catch {}
    }
  });

  // コマンド
  pi.registerCommand("tidy", {
    description: "Toggle tidy mode (compact tool/thinking display). on/off または トグル.",
    handler: async (args, ctx) => {
      const arg = (args ?? "").trim().toLowerCase();

      if (arg === "on") {
        mode = "tidy";
      } else if (arg === "off") {
        mode = "detailed";
      } else if (arg === "status") {
        ctx.ui.notify(`tidy mode: ${mode}`, "info");
        return;
      } else {
        mode = mode === "tidy" ? "detailed" : "tidy";
      }

      applyMode(ctx);
      ctx.ui.notify(`tidy mode: ${mode}`, "info");
    },
  });
}
