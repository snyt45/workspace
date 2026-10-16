#!/usr/bin/env python3
"""requirements-map の decision.json から、1枚で読めて根拠をその場で開ける HTML を作る。判断はしない。

使い方:
  tour.py DECISION [-o OUT]     既定の出力は DECISION と同じ場所の tour.html

やること:
  1. decision.json を検査する（量の上限 LIMITS / CHARS、軸ごとの評価が全部の案にあるか、根拠の id が evidence.json にあるか、根拠も note も無い項目が無いか）。NG なら exit 1
  2. evidence.json を code-evidence の evidence.py で照合する（--strict。確認が済んでいない事実があれば NG）。NG なら exit 1
  3. 1枚のページを作る: 背景・決めること・案のカード・案ごとの見積と聞くこと。根拠は文中の番号で、押すとその行の真下に
     事実が1行で開き、調べ方・資料・コード・検索はさらにその中の「確かめ方」に畳む
  4. コードは各リポジトリの指定コミットから読み（evidence.py）、HTML に埋め込む。LLM の文は使わない
"""
import argparse, html, json, os, re, sys

sys.path.insert(0, os.path.expanduser("~/.claude/skills/code-evidence/scripts"))
import evidence  # noqa: E402

CONTEXT = 2  # 根拠の行の前後に出す行数


# eval の文中の [F1] は、その直前の節を支える根拠。ページではその節を光らせる
REF = re.compile(r"\[(F\d+)\]")


def eval_grounds(c):
    """評価の文の根拠。文中の [F1] と grounds を、出てきた順に"""
    gs = list(dict.fromkeys(REF.findall(c.get("text", ""))))
    return gs + [g for g in c.get("grounds", []) if g not in gs]


def plain(text):
    return REF.sub("", text)


def option_grounds(o):
    """案の根拠。軸ごとの評価に出てくる根拠を、出てきた順に"""
    gs = list(o.get("grounds", []))
    for c in o.get("eval", {}).values():
        gs += [g for g in eval_grounds(c) if g not in gs]
    return gs


# 人と話しながら使える量の上限。超えたら削るか、論点を分ける
LIMITS = {"background": 3, "axes": 3, "options": 3, "estimate": 5, "ask": 4, "facts": 10}
CHARS = {"background": 70, "question": 40, "option": 30, "eval": 45, "short": 16, "item": 40, "why": 50}


def conds(dec):
    """選んだ場合の欄。if は1案なら {option, ...}、複数案なら その配列"""
    c = dec.get("if") or []
    return [c] if isinstance(c, dict) else c


def cond_items(dec, k):
    return [x for c in conds(dec) for x in c.get(k, [])]


def validate_size(dec):
    ng = []
    counts = {"background": len(dec["background"]), "axes": len(dec.get("axes", [])), "options": len(dec["options"]),
              "facts": len({g for o in dec["options"] for g in option_grounds(o)}
                           | {g for k in ("estimate", "ask") for x in cond_items(dec, k) for g in x.get("grounds", [])})}
    for k, n in counts.items():
        if n > LIMITS[k]:
            ng.append(f"{k} が {n} 個（{LIMITS[k]} 個まで）。削るか、論点を分ける")
    # 見積と聞くことの上限は案ごと
    for c in conds(dec):
        for k in ("estimate", "ask"):
            n = len(c.get(k, []))
            if n > LIMITS[k]:
                ng.append(f"{c.get('option')} を選んだ場合の {k} が {n} 個（{LIMITS[k]} 個まで）。削るか、論点を分ける")
    texts = [("background", b) for b in dec["background"]] + [("question", dec["question"])]
    texts += [("option", o["label"]) for o in dec["options"]]
    texts += [("eval", plain(c.get("text", ""))) for o in dec["options"] for c in o.get("eval", {}).values()]
    texts += [("short", c["short"]) for o in dec["options"] for c in o.get("eval", {}).values() if "short" in c]
    for o in dec["options"]:
        for a, c in o.get("eval", {}).items():
            if not c.get("short"):
                ng.append(f"案 {o['id']}・{a}: short（カードに太字で出す一言）が無い")
    texts += [("item", x["label"]) for k in ("estimate", "ask") for x in cond_items(dec, k)]
    texts += [("why", x.get("why", "")) for k in ("estimate", "ask") for x in cond_items(dec, k)]
    for k in ("estimate", "ask"):
        for x in cond_items(dec, k):
            if x.get("grounds") and not x.get("why"):
                ng.append(f"{k}「{x['label'][:20]}」: 根拠があるのに why（なぜ要るか）が無い")
    for k, t in texts:
        if len(t) > CHARS[k]:
            ng.append(f"{k}「{t[:20]}…」が {len(t)} 字（{CHARS[k]} 字まで）")
    return ng


def validate(dec, facts):
    ng = []
    if "recommend" in dec:
        ng.append("recommend は使わない。案は axes（判断の軸）ごとの eval で比べる")
    axes = [a["id"] for a in dec.get("axes", [])]
    if not axes:
        ng.append("axes（判断の軸）が無い")
    for o in dec["options"]:
        o["grounds"] = option_grounds(o)
        for a in axes:
            if a not in o.get("eval", {}):
                ng.append(f"案 {o['id']}: 軸 {a} の評価が無い")
        for a, c in o.get("eval", {}).items():
            if a not in axes:
                ng.append(f"案 {o['id']}: 軸 {a} は axes に無い")
            refs = REF.findall(c.get("text", ""))
            extra = [g for g in c.get("grounds", []) if g not in refs]
            if refs and extra:
                ng.append(f"案 {o['id']}・{a}: {', '.join(extra)} が文中に無い。[F1] のように、支える節の直後に書く")
    items = [("案 " + o["id"], o) for o in dec["options"]]
    items += [("見積", x) for x in cond_items(dec, "estimate")]
    items += [("聞くこと", x) for x in cond_items(dec, "ask")]
    for kind, it in items:
        if not it.get("grounds") and not it.get("note"):
            ng.append(f"{kind}「{it['label']}」: grounds も note も無い")
        for g in it.get("grounds", []):
            if g not in facts:
                ng.append(f"{kind}「{it['label']}」: 根拠 {g} が evidence.json に無い")
    ids, seen = {o["id"] for o in dec["options"]}, set()
    for c in conds(dec):
        if c.get("option") not in ids:
            ng.append(f"if.option {c.get('option')} が options に無い")
        if c.get("option") in seen:
            ng.append(f"if.option {c.get('option')} が2回ある")
        seen.add(c.get("option"))
    return ng + validate_size(dec)


def facts_used(dec):
    """ページに出る事実。案の評価と、選んだ場合の見積・聞くことの根拠"""
    gs = [g for o in dec["options"] for g in option_grounds(o)]
    gs += [g for k in ("estimate", "ask") for x in cond_items(dec, k) for g in x.get("grounds", [])]
    return sorted(set(gs))


def kind(n, text, ev):
    """key = snippet の行（強く光らせる）、in = 根拠の範囲、ctx = 前後の行"""
    if not ev["start"] <= n <= ev["end"]:
        return "ctx"
    t = evidence.norm(text)
    if t and any(t in evidence.norm(sn) or evidence.norm(sn) in t for sn in ev.get("snippet", [])):
        return "key"
    return "in"


def fact_payload(data, fact, res):
    code = []
    for ev in res["evidence"]:
        lines = ev["file_lines"]
        lo, hi = max(1, ev["start"] - CONTEXT), min(len(lines), ev["end"] + CONTEXT)
        code.append({"label": ev.get("label", ""), "repo": ev["repo"], "path": ev["path"],
                     "start": ev["start"], "end": ev["end"],
                     "lines": [[n, lines[n - 1], kind(n, lines[n - 1], ev)] for n in range(lo, hi + 1)]})
    searches = [{"what": s["what"], "pattern": s["pattern"], "repos": s["repos"], "count": len(s["hits"]),
                 "hits": [{"repo": r, "path": p, "line": n, "text": t.strip(), "note": s.get("notes", {}).get(f"{r}:{p}:{n}", "")}
                          for r, p, n, t in s["hits"]]}
                for s in res["searches"]]
    return {"id": fact["id"], "claim": fact["claim"], "method": fact.get("method", ""), "absence": evidence.is_absence(fact),
            "scope": fact.get("scope", []),
            "verdict": fact.get("verdict", ""), "verdict_reason": fact.get("verdict_reason", ""),
            "code": code, "searches": searches, "sources": fact.get("sources", [])}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("decision")
    ap.add_argument("-o", "--out")
    a = ap.parse_args()
    base = os.path.dirname(os.path.abspath(a.decision))
    dec = json.load(open(a.decision, encoding="utf-8"))
    data = evidence.load(os.path.join(base, dec["evidence"]))
    facts = {f["id"]: f for f in data["facts"]}

    ng = validate(dec, facts)
    ev_ng, res = evidence.check(data, strict=True)
    ng += ev_ng
    if ng:
        print("## NG")
        print("\n".join(f"- {x}" for x in ng))
        sys.exit(1)

    payload = {"title": dec["title"], "background": dec["background"], "question": dec["question"],
               "question_then": dec.get("question_then", ""), "axes": dec["axes"],
               "options": dec["options"], "ifs": conds(dec),
               "facts": {g: fact_payload(data, facts[g], res[g]) for g in facts_used(dec)}}
    out = a.out or os.path.join(base, "tour.html")
    tpl = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "tour.html"), encoding="utf-8").read()
    page = tpl.replace("__TITLE__", html.escape(dec["title"])).replace(
        "__DATA__", json.dumps(payload, ensure_ascii=False).replace("</", "<\\/"))
    open(out, "w", encoding="utf-8").write(page)
    print(f"{out}（事実 {len(payload['facts'])}）")


if __name__ == "__main__":
    main()
