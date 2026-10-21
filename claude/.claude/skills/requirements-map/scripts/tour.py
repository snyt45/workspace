#!/usr/bin/env python3
"""requirements-map の decision.json から、1枚で読めて根拠をその場で開ける HTML を作る。判断はしない。

使い方:
  tour.py DECISION [-o OUT]     既定の出力は DECISION と同じ場所の tour.html

やること:
  1. decision.json を検査する（量の上限 LIMITS / CHARS、軸ごとの評価と short が全部の案にあるか、根拠の id が evidence.json にあるか、
     根拠も note も無い項目が無いか、根拠があるのに why が無い項目が無いか、asis・ずれ・changes の欄の抜けと根拠、[F1] を書けない欄に書いていないか）。NG なら exit 1
  2. evidence.json を code-evidence の evidence.py で照合する（--strict。確認が済んでいない事実があれば NG）。NG なら exit 1
  3. 1枚のページを作る: 背景・決めること・（asis があれば）今の仕組みと要望とのずれ・案が今の仕組みをどう変えるか・案のカード・
     案ごとの見積と聞くこと・（asis があれば）最後に畳んだ asis.md。根拠は文中の番号で、押すと右のパネル（狭い画面では下のシート）に
     その事実（主張・確かめ方・AI の確認・コード・検索）が出る
  4. コードは各リポジトリの指定コミットから読み（evidence.py）、HTML に埋め込む。LLM の文は使わない
"""
import argparse, html, json, os, re, sys

sys.path.insert(0, os.path.expanduser("~/.claude/skills/code-evidence/scripts"))
import evidence  # noqa: E402

CONTEXT = 2  # 根拠の行の前後に出す行数


# 文中の [F1] は、その直前の節を支える根拠
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
LIMITS = {"background": 3, "axes": 3, "options": 3, "estimate": 5, "ask": 4, "facts": 10, "elements": 6, "flow": 4, "gaps": 6, "open": 5}
CHARS = {"background": 70, "question": 40, "option": 30, "eval": 45, "short": 16, "item": 40, "why": 50,
         "role": 24, "asis": 60, "node": 18, "change": 20,
         "unit": 30, "want": 30, "where": 24, "now": 45, "open": 60}


def elements(dec):
    """今の仕組みの要素。asis を呼んだ論点だけにある"""
    return (dec.get("asis") or {}).get("elements", [])


def asis_md(dec, base):
    """asis.md の本文。ページに畳んで入れ、1ファイルで完結させる"""
    link = (dec.get("asis") or {}).get("link")
    if not link:
        return ""
    path = os.path.join(base, link)
    return open(path, encoding="utf-8").read() if os.path.exists(path) else None


def no_ref_fields(dec):
    """[F1] を書けない欄。ここに書いても facts_used が拾わず、ページで押せない番号になる"""
    out = [("background", b) for b in dec.get("background", [])] + [("question", dec.get("question", ""))]
    out += [("question_then", q) for q in (dec.get("question_then") or [])]
    for o in dec.get("options", []):
        out += [("案の label", o.get("label", "")), ("案の note", o.get("note", ""))]
        out += [(f"案 {o.get('id')} の short", c.get("short", "")) for c in o.get("eval", {}).values()]
    for c in conds(dec):
        for k in ("estimate", "ask"):
            for x in c.get(k, []):
                out += [(f"{k} の {f}", x.get(f, "")) for f in ("label", "why", "note", "when")]
    for e in elements(dec):
        out += [("asis の role", e.get("role", ""))] + [("asis の flow", n.get(k, "")) for n in e.get("flow", []) for k in ("t", "no")]
    gp = dec.get("gaps") or {}
    out += [("gaps の unit", gp.get(k, "")) for k in ("unit_now", "unit_want")]
    out += [(f"gaps の {k}", r.get(k, "")) for r in gp.get("rows", []) for k in ("want", "where")]
    out += [("open", t) for t in (dec.get("open") or [])]
    return [f"{where}「{str(t)[:15]}…」に [F1] は書けない（根拠は text / now / eval の文に）" for where, t in out if t and REF.search(str(t))]


def validate_asis(dec, facts):
    """今の仕組みと、案が今の仕組みをどう変えるか（changes）。要素 × 案の抜けを NG にする"""
    ng, els = no_ref_fields(dec), elements(dec)
    if not els:
        if dec.get("changes"):
            ng.append("changes があるのに asis.elements が無い")
        if dec.get("gaps"):
            ng.append("gaps があるのに asis.elements が無い")
        return ng
    if len(els) > LIMITS["elements"]:
        ng.append(f"asis の要素が {len(els)} 個（{LIMITS['elements']} 個まで）。To-Be で移し先を決める要素だけにする")
    ids = [o["id"] for o in dec["options"]]
    ch = dec.get("changes") or {}
    for e in els:
        for k in ("id", "name", "role", "text"):
            if not e.get(k):
                ng.append(f"asis の要素「{e.get('name', e.get('id', '?'))}」: {k} が無い")
        for k, ck in (("role", "role"), ("text", "asis")):
            t = plain(e.get(k) or "")
            if len(t) > CHARS[ck]:
                ng.append(f"asis「{e.get('name')}」の {k} が {len(t)} 字（{CHARS[ck]} 字まで）")
        if not REF.findall(e.get("text") or ""):
            ng.append(f"asis「{e.get('name')}」: text に根拠 [F1] が無い")
        for g in REF.findall(e.get("text") or ""):
            if g not in facts:
                ng.append(f"asis「{e.get('name')}」: 根拠 {g} が evidence.json に無い")
        flow = [] if (dec.get("asis") or {}).get("diagram") else e.get("flow", [])
        if len(flow) > LIMITS["flow"]:
            ng.append(f"asis「{e.get('name')}」の flow が {len(flow)} 個（{LIMITS['flow']} 個まで）")
        for n in flow:
            for k in ("t", "no"):
                if len(n.get(k) or "") > CHARS["node"]:
                    ng.append(f"asis「{e.get('name')}」の flow「{n.get(k)[:10]}…」が {CHARS['node']} 字を超える")
        row = ch.get(e.get("id")) or {}
        if not isinstance(row, dict):
            ng.append(f"changes の {e.get('id')} は {{案の id: 文}} の形にする")
            row = {}
        for o in ids:
            v = row.get(o)
            if not isinstance(v, str) or not v:
                ng.append(f"changes: 要素 {e.get('id')} × 案 {o} が無い。そのままなら「そのまま」と書く")
                continue
            if len(plain(v)) > CHARS["change"]:
                ng.append(f"changes: {e.get('id')} × {o}「{v[:10]}…」が {CHARS['change']} 字を超える")
            ng += [f"changes: {e.get('id')} × {o}: 根拠 {g} が evidence.json に無い" for g in REF.findall(v) if g not in facts]
    gp = dec.get("gaps") or {}
    if gp:
        for k in ("unit_now", "unit_want"):
            if not gp.get(k):
                ng.append(f"gaps.{k}（制御の単位）が無い")
            elif len(plain(gp[k])) > CHARS["unit"]:
                ng.append(f"gaps.{k} が {CHARS['unit']} 字を超える")
        rows = gp.get("rows", [])
        if len(rows) > LIMITS["gaps"]:
            ng.append(f"gaps の行が {len(rows)} 個（{LIMITS['gaps']} 個まで）")
        for r in rows:
            for k in ("want", "where", "now"):
                if not r.get(k):
                    ng.append(f"gaps「{(r.get('want') or '?')[:15]}」: {k} が無い")
                elif len(plain(r[k])) > CHARS[k]:
                    ng.append(f"gaps「{r[k][:15]}…」の {k} が {CHARS[k]} 字を超える")
            gs = REF.findall(r.get("now") or "")
            if not gs:
                ng.append(f"gaps「{r.get('want', '?')[:15]}」: now に根拠 [F1] が無い")
            ng += [f"gaps「{r.get('want', '?')[:15]}」: 根拠 {g} が evidence.json に無い" for g in gs if g not in facts]
    op = dec.get("open") or []
    if len(op) > LIMITS["open"]:
        ng.append(f"open（決めていないこと）が {len(op)} 個（{LIMITS['open']} 個まで）")
    ng += [f"open「{str(t)[:15]}…」が {CHARS['open']} 字を超える" for t in op if len(str(t)) > CHARS["open"]]
    dg = (dec.get("asis") or {}).get("diagram", "")
    if dg and not dg.lstrip().startswith("<svg"):
        ng.append("asis.diagram は <svg> で始める（インラインの SVG）")
    for k in ch:
        if k not in {e.get("id") for e in els}:
            ng.append(f"changes の {k} が asis.elements に無い")
    return ng


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
    return ng + validate_size(dec) + validate_asis(dec, facts)


def facts_used(dec, md=""):
    """ページに出る事実。案の評価、選んだ場合の見積・聞くこと、今の仕組み（asis.md を含む）の根拠"""
    gs = [g for o in dec["options"] for g in option_grounds(o)]
    gs += [g for k in ("estimate", "ask") for x in cond_items(dec, k) for g in x.get("grounds", [])]
    gs += [g for e in elements(dec) for g in REF.findall(e.get("text", ""))]
    gs += [g for row in (dec.get("changes") or {}).values() for t in row.values() for g in REF.findall(t)]
    gs += [g for r in (dec.get("gaps") or {}).get("rows", []) for g in REF.findall(r.get("now", ""))]
    gs += REF.findall(md or "")
    return sorted(set(gs), key=lambda g: int(g[1:]))


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
    md = asis_md(dec, base)
    if md is None:
        ng.append(f"asis.link の {dec['asis']['link']} が無い")
    for g in REF.findall(md or ""):
        if g not in facts:
            ng.append(f"asis.md の根拠 {g} が evidence.json に無い")
    ev_ng, res = evidence.check(data, strict=True)
    ng += ev_ng
    if ng:
        print("## NG")
        print("\n".join(f"- {x}" for x in ng))
        sys.exit(1)

    payload = {"title": dec["title"], "background": dec["background"], "question": dec["question"],
               "question_then": dec.get("question_then", ""), "axes": dec["axes"],
               "options": dec["options"], "ifs": conds(dec),
               "asis": dec.get("asis") or {}, "changes": dec.get("changes") or {}, "asis_md": md or "", "gaps": dec.get("gaps") or {}, "open": dec.get("open") or [],
               "facts": {g: fact_payload(data, facts[g], res[g]) for g in facts_used(dec, md)}}
    out = a.out or os.path.join(base, "tour.html")
    tpl = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "tour.html"), encoding="utf-8").read()
    page = tpl.replace("__TITLE__", html.escape(dec["title"])).replace(
        "__DATA__", json.dumps(payload, ensure_ascii=False).replace("</", "<\\/"))
    open(out, "w", encoding="utf-8").write(page)
    print(f"{out}（事実 {len(payload['facts'])}）")


if __name__ == "__main__":
    main()
