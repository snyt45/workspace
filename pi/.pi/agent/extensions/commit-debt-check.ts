/**
 * Commit Debt Check Extension
 *
 * git commit 実行後、~/work/claude-obsidian/debt/<repo>.md に Lv1/Lv2 の
 * 未解消な理解負債が残っていれば気づかせる。commit はブロックしない
 * （AGENTS.md の理解負債ワークフロー参照）。
 */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const COMMIT_PATTERN = /\bgit\s+commit\b/;
const DEBT_DIR = path.join(os.homedir(), "work/claude-obsidian/debt");

function findOpenDebts(repoName: string): string[] {
	const file = path.join(DEBT_DIR, `${repoName}.md`);
	if (!fs.existsSync(file)) return [];

	const themes: string[] = [];
	for (const line of fs.readFileSync(file, "utf-8").split("\n")) {
		const m = line.match(/^##\s+Lv[12]\s+(.+)$/);
		if (m) themes.push(m[1].trim());
	}
	return themes;
}

export default function (pi: ExtensionAPI) {
	pi.on("tool_result", async (event, ctx) => {
		if (event.toolName !== "bash" || event.isError) return undefined;

		const command = String(event.input.command ?? "");
		if (!COMMIT_PATTERN.test(command)) return undefined;

		const { stdout, code } = await pi.exec("git", ["rev-parse", "--show-toplevel"], { cwd: ctx.cwd });
		const repoName = code === 0 ? path.basename(stdout.trim()) : "general";

		const themes = findOpenDebts(repoName);
		if (themes.length === 0) return undefined;

		const message = `未解消の理解負債があります: ${themes.join(" / ")}`;

		if (ctx.hasUI) {
			ctx.ui.notify(message, "warning");
		}

		return {
			content: [
				...event.content,
				{
					type: "text" as const,
					text: `\n[debt-check] ${message}\n必要なら /debt-check で1つだけ確認してください。`,
				},
			],
		};
	});
}
