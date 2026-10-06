#!/usr/bin/env python3
"""quiz-grade — AskUserQuestion の quiz を、回答した瞬間に採点してユーザーに見せる。

PostToolUse(AskUserQuestion) hook。Claude の応答を待たずに、正誤と解説を systemMessage で出す。
採点の鍵は tool_input.metadata.source に `quiz:` + JSON で入れる（metadata はユーザーに表示されない）:
  quiz:{"<question>": {"answer": "<正解の label>", "why": "<解説>"}, ...}
鍵の無い問い（採点しない問い）は何もしない。自由回答は Claude に採点を任せる。
"""
import json
import sys

PREFIX = "quiz:"


def load_key(tool_input):
    source = (tool_input.get("metadata") or {}).get("source", "")
    if not source.startswith(PREFIX):
        return {}
    return json.loads(source[len(PREFIX):])


def grade(question, answer, key):
    labels = [o["label"] for o in question.get("options", [])]
    if answer == key["answer"]:
        head = "✅ 正解"
    elif answer == "わからない":
        head = "🤔 わからない"
    elif answer in labels:
        head = f"❌ 不正解（あなたの回答: {answer}）"
    else:
        return "📝 自由回答なので Claude が採点します"
    reasons = "\n".join(f"・{s}。" for s in key["why"].split("。") if s.strip())
    return f"{head}\n→ {key['answer']}\n\n{reasons}"


def main():
    hook = json.load(sys.stdin)
    tool_input = hook.get("tool_input", {})
    key = load_key(tool_input)
    if not key:
        return
    answers = (hook.get("tool_response") or {}).get("answers", {})
    results = [grade(q, answers.get(q["question"], ""), key[q["question"]])
               for q in tool_input.get("questions", []) if q["question"] in key]
    print(json.dumps({
        "systemMessage": "\n\n".join(results),
        "hookSpecificOutput": {
            "hookEventName": "PostToolUse",
            "additionalContext": "quiz は hook が採点し、正誤と解説をユーザーに表示済み。採点を繰り返さず、"
                                 "誤答から見える誤解の深掘りと次の問い・説明に進む。自由回答だけは Claude が採点する。",
        },
    }, ensure_ascii=False))


if __name__ == "__main__":
    try:
        main()
    except Exception as err:  # 採点の失敗で会話を止めない
        print(f"quiz-grade: {err}", file=sys.stderr)
