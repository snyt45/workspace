/**
 * pi-tidy
 *
 * tool 実行結果を折りたたんで表示。必要な個所だけ Ctrl+O かクリックで展開。
 * Claude ライクな表示を Pi のデフォルトに。
 *
 * thinking の非表示は settings.json の hideThinkingBlock で制御。
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    try {
      ctx.ui.setToolsExpanded(false);
    } catch {
      // 安全のため
    }
  });

  // ターン開始時にも強制
  pi.on("turn_start", async (_event, ctx) => {
    try { ctx.ui.setToolsExpanded(false); } catch {}
  });
}
