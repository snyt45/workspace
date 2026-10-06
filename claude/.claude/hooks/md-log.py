#!/usr/bin/env python3
"""md-log — 会話を markdown ファイルに写す（Obsidian で描画して読むため）。

写し先: このセッションで Write した、frontmatter に `md-log: true` を持つ最後のファイル。
写す中身: そのファイルを作った後の、ユーザーの発言・Claude の本文・AskUserQuestion の問いと回答（quiz なら正誤と解説も）。
ツールの実行や思考は写さない。

毎回 transcript から写し先の全体を作り直す（冪等。状態ファイルを持たない）。
写し先を Obsidian で直接編集しても、次の書き出しで上書きされる。写し先を消すと、以後は写さない。

hook:
  Stop                          … ターンの終わりに書き出す
  PreToolUse(AskUserQuestion)   … 回答前の問いを先に見せる（選択肢だけ。正解は書かない）
"""
import json
import re
import sys
from pathlib import Path

MARKER = re.compile(r"\A---\n(?:.*\n)*?md-log:\s*true\s*\n(?:.*\n)*?---\n", re.M)
NOISE = re.compile(r"<(system-reminder|command-[a-z]+|local-command-[a-z]+)>.*?</\1>", re.S)


def callout(kind, title, body=""):
    lines = [f"> [!{kind}] {title}"]
    if body:
        lines.append(">")
        lines += [f"> {l}" if l else ">" for l in body.splitlines()]
    return "\n".join(lines)


def quiz_key(tool_input):
    """quiz-grade hook と同じ鍵（metadata.source の `quiz:` + JSON）。無ければ空"""
    source = (tool_input.get("metadata") or {}).get("source", "")
    return json.loads(source[5:]) if source.startswith("quiz:") else {}


def question_block(tool_input, answers=None):
    out, key = [], quiz_key(tool_input)
    for q in tool_input.get("questions", []):
        opts = "\n".join(f"{i}. {o['label']}" for i, o in enumerate(q.get("options", []), 1))
        out.append(callout("question", q["question"], opts))
        if answers is None:
            continue
        answer, k = answers.get(q["question"], "(なし)"), key.get(q["question"])
        if k is None:
            out.append(callout("success", "回答", answer))
        elif answer == k["answer"]:
            out.append(callout("success", f"正解: {answer}", k["why"]))
        else:
            out.append(callout("failure", f"回答: {answer}（正解: {k['answer']}）", k["why"]))
    return "\n\n".join(out)


def main():
    hook = json.load(sys.stdin)
    transcript = Path(hook.get("transcript_path", ""))
    if not transcript.is_file():
        return

    entries = [json.loads(l) for l in transcript.open(encoding="utf-8") if l.strip()]
    entries = [e for e in entries if not e.get("isSidechain")]

    target, header, start = None, "", 0
    for i, e in enumerate(entries):
        for c in content_of(e):
            if c.get("type") == "tool_use" and c.get("name") == "Write":
                text = c["input"].get("content", "")
                if MARKER.match(text):
                    target, header, start = Path(c["input"]["file_path"]), text.rstrip(), i + 1
    if target is None or not target.exists():  # 写し先を消したら写すのをやめる
        return

    blocks, pending = [header], {}
    for e in entries[start:]:
        if e.get("isMeta") or e.get("type") not in ("user", "assistant"):
            continue
        content = e["message"].get("content")
        if e["type"] == "user" and isinstance(content, str):
            text = NOISE.sub("", content).strip()
            if text:
                blocks.append(callout("quote", "YOU", text))
            continue
        for c in content_of(e):
            if c.get("type") == "text":
                text = NOISE.sub("", c["text"]).strip()
                if not text:
                    continue
                blocks.append(callout("quote", "YOU", text) if e["type"] == "user" else text)
            elif c.get("type") == "tool_use" and c.get("name") == "AskUserQuestion":
                pending[c["id"]] = c["input"]
            elif c.get("type") == "tool_result" and c.get("tool_use_id") in pending:
                result = e.get("toolUseResult")
                answers = result.get("answers", {}) if isinstance(result, dict) else {}
                blocks.append(question_block(pending.pop(c["tool_use_id"]), answers))

    if hook.get("hook_event_name") == "PreToolUse" and hook.get("tool_name") == "AskUserQuestion":
        blocks.append(question_block(hook.get("tool_input", {})))

    target.write_text("\n\n".join(blocks) + "\n", encoding="utf-8")


def content_of(entry):
    content = (entry.get("message") or {}).get("content")
    return content if isinstance(content, list) else []


if __name__ == "__main__":
    try:
        main()
    except Exception as err:  # 写しの失敗で会話を止めない
        print(f"md-log: {err}", file=sys.stderr)
