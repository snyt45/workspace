/**
 * pi-tidy
 *
 * tool 実行結果を折りたたみ、thinking を簡潔ラベルに。
 * 必要な個所だけ Ctrl+O かクリックで展開。
 * Claude ライクな表示を Pi のデフォルトに。
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    try {
      ctx.ui.setToolsExpanded(false);
      ctx.ui.setHiddenThinkingLabel("[🧠 thinking]");
      // pi-status-footer に通知
      pi.events.emit("pi-tidy:mode", { mode: true });
    } catch {
      // 安全のため
    }
  });

  // ターン開始時にも強制（ユーザーが手動で展開しても次ターンで戻る）
  pi.on("turn_start", async (_event, ctx) => {
    try { ctx.ui.setToolsExpanded(false); } catch {}
  });
}
