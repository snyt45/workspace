#!/usr/bin/env python3
"""code-evidence の evidence.json を照合する。判断はしない。コードは各リポジトリの指定コミットから git で読むので、何度動かしても同じ結果になる。

使い方:
  evidence.py FILE                    照合して結果を出す。NG があれば exit 1
  evidence.py FILE --strict           確認が済んでいない事実（資料のみ を除く）も NG にする。ページを作る前に使う
  evidence.py FILE --record RESULT     確認の AI が返した {"F1": {"verdict": "支持", "reason": "..."}, ...} を書き込む
                                      書き込むときに、その事実の中身のハッシュも記録する

evidence.json の形:
  {
    "title": "...",
    "repos": {"toypo-api": {"path": "~/work/toypo-api", "commit": "063537a22dcb"}, ...},
    "facts": [{
      "id": "F1", "claim": "主張", "method": "調べ方（起点 → 探し方 → どこまで）", "scope": ["toypo-api", ...],
      "evidence": [{"label": "何のコードか: 何をしているか", "repo": "toypo-api", "path": "config/routes.rb",
                    "lines": "144-145", "snippet": ["要の行", ...]}],
      "searches": [{"what": "潰すもの", "repos": [...], "pattern": "PCRE", "pathspec": ["app/models"], "count": 11,
                    "notes": {"toypo-api:app/controllers/x.rb:70": "関係ないヒットの理由"}}],
      "sources": [{"label": "資料の名前", "url": "..."}],
      "verdict": "" | "支持" | "一部" | "不支持" | "資料のみ",
      "verdict_reason": "確認した AI の結論を1文",
      "verified_hash": "確認したときの中身のハッシュ（--record が書く）"
    }]
  }
  pathspec は任意。git grep の -- の後ろに渡す（リポジトリの中のパスで絞る）
  notes は任意。関係ないヒットに理由を付ける。キーは repo:path:line で、いまのヒットに無いキーは NG

確認の状態（status）:
  verdict があり、verified_hash がいまの中身と一致するときだけ verdict を有効とみなす
  一致しなければ「確認の後に中身が変わった」として、確認は まだ（""）に戻る
  資料のみ は evidence と searches が無い事実にだけ付けられる

検査:
  - repos の各コミットが存在すること
  - evidence: label があること。そのコミットにファイルと行があり、snippet の各要素が行の範囲にあること（空白の違いは無視）
  - searches: 各リポジトリのコミットで git grep -P し、ヒットの行数が count と一致すること。notes のキーがヒットにあること
  - 根拠（evidence / searches / sources）が1つも無い事実は 未確認 として数える
  - verdict が決まった値であること
  - --strict のときは、status が 支持 / 資料のみ でない事実を NG にする
無いことの主張（claim に だけ / しか / 無い / しない / できない / 見ない、文末や句読点の直前の ない）で searches が無いものは、注意として出す（NG にはしない）
ほかのスクリプトからは load()、check()、status()、is_absence() を使う
"""
import argparse, hashlib, json, os, re, subprocess, sys

VERDICTS = {"", "支持", "一部", "不支持", "資料のみ"}
ABSENCE = re.compile(r"だけ|しか|無い|しない|できない|見ない|ない(?=$|[。、）)])")
HASHED = ("claim", "method", "scope", "evidence", "searches", "sources")


def norm(s):
    return re.sub(r"\s+", "", s)


def is_absence(fact):
    """無いことの主張か。claim の言葉で決める"""
    return bool(ABSENCE.search(fact.get("claim", "")))


def content_hash(fact):
    body = json.dumps({k: fact.get(k) for k in HASHED}, ensure_ascii=False, sort_keys=True)
    return hashlib.sha256(body.encode()).hexdigest()[:16]


def status(fact):
    """有効な確認の結果。確認の後に中身が変わっていれば "" """
    v = fact.get("verdict", "")
    if v and fact.get("verified_hash") == content_hash(fact):
        return v
    return ""


def stale(fact):
    return bool(fact.get("verdict")) and status(fact) == ""


def git(repo, *args):
    r = subprocess.run(["git", "-C", repo["abspath"], *args], capture_output=True, text=True)
    return r.returncode, r.stdout, r.stderr


def load(path):
    data = json.load(open(path, encoding="utf-8"))
    for name, repo in data["repos"].items():
        repo["name"] = name
        repo["abspath"] = os.path.abspath(os.path.expanduser(repo["path"]))
    return data


def read_lines(repo, path):
    code, out, _ = git(repo, "show", f"{repo['commit']}:{path}")
    return out.splitlines() if code == 0 else None


def line_range(spec):
    s, _, e = spec.partition("-")
    return int(s), int(e or s)


def run_search(data, search):
    """[(repo, path, line, text)] を返す"""
    hits = []
    for name in search["repos"]:
        repo = data["repos"][name]
        code, out, err = git(repo, "grep", "-n", "-I", "-P", "-e", search["pattern"], repo["commit"], "--", *search.get("pathspec", []))
        if code not in (0, 1):
            raise RuntimeError(f"{name}: {err.strip()}")
        for l in out.splitlines():
            _, path, line, text = l.split(":", 3)
            hits.append((name, path, int(line), text))
    return hits


def check(data, strict=False):
    """(ng, 結果) を返す。結果は fact id ごとに {evidence: [{..., file_lines}], searches: [{..., hits}]}"""
    ng, result = [], {}
    for name, repo in data["repos"].items():
        if git(repo, "cat-file", "-e", f"{repo['commit']}^{{commit}}")[0] != 0:
            ng.append(f"repos.{name}: コミット {repo['commit']} が無い")
    if ng:
        return ng, result
    for f in data["facts"]:
        fid, out = f["id"], {"evidence": [], "searches": []}
        result[fid] = out
        v = f.get("verdict", "")
        if v not in VERDICTS:
            ng.append(f"{fid}: verdict「{v}」は 空 / 支持 / 一部 / 不支持 / 資料のみ のどれか")
        if v == "資料のみ" and (f.get("evidence") or f.get("searches")):
            ng.append(f"{fid}: コードの根拠があるのに verdict が 資料のみ")
        if strict and status(f) not in ("支持", "資料のみ"):
            why = "確認の後に中身が変わった" if stale(f) else (f"確認が {v}" if v else "確認がまだ")
            ng.append(f"{fid}: {why}（新しい確認の AI に読ませて --record する）")
        for ev in f.get("evidence", []):
            where = f"{ev['repo']}:{ev['path']}:{ev['lines']}"
            if not ev.get("label"):
                ng.append(f"{fid}: {where} に label が無い")
            repo = data["repos"].get(ev["repo"])
            lines = read_lines(repo, ev["path"]) if repo else None
            if lines is None:
                ng.append(f"{fid}: ファイルが無い {where}"); continue
            s, e = line_range(ev["lines"])
            if not (1 <= s <= e <= len(lines)):
                ng.append(f"{fid}: 行が範囲外 {where}（{len(lines)} 行）"); continue
            body = norm("".join(lines[s - 1:e]))
            for sn in ev.get("snippet", []):
                if norm(sn) not in body:
                    ng.append(f"{fid}: 抜き出し「{sn}」が {where} に無い")
            out["evidence"].append({**ev, "start": s, "end": e, "file_lines": lines})
        for se in f.get("searches", []):
            try:
                hits = run_search(data, se)
            except RuntimeError as err:
                ng.append(f"{fid}: 検索「{se['what']}」 {err}"); continue
            if len(hits) != se["count"]:
                ng.append(f"{fid}: 検索「{se['what']}」は count {se['count']} と書いたが、いまは {len(hits)} 件")
            keys = {f"{r}:{p}:{n}" for r, p, n, _ in hits}
            for k in se.get("notes", {}):
                if k not in keys:
                    ng.append(f"{fid}: 検索「{se['what']}」の notes の {k} がヒットに無い")
            out["searches"].append({**se, "hits": hits})
    return ng, result


def record(path, result_path):
    raw = json.load(open(path, encoding="utf-8"))
    res = json.load(open(result_path, encoding="utf-8"))
    by_id = {f["id"]: f for f in raw["facts"]}
    for fid, r in res.items():
        if fid not in by_id:
            sys.exit(f"{fid} は {path} に無い")
        f = by_id[fid]
        f["verdict"], f["verdict_reason"] = r["verdict"], r.get("reason", "")
        f["verified_hash"] = content_hash(f)
    with open(path, "w", encoding="utf-8") as fp:
        json.dump(raw, fp, ensure_ascii=False, indent=2)
        fp.write("\n")
    print(f"{len(res)} 件の確認を書き込んだ")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("file")
    ap.add_argument("--strict", action="store_true")
    ap.add_argument("--record")
    a = ap.parse_args()
    if a.record:
        record(a.file, a.record)
    data = load(a.file)
    ng, _ = check(data, strict=a.strict)
    facts = data["facts"]
    unverified = [f for f in facts if not (f.get("evidence") or f.get("searches") or f.get("sources"))]
    todo = [f for f in facts if f not in unverified and status(f) not in ("支持", "資料のみ")]
    read_only = [f for f in facts if is_absence(f) and not f.get("searches") and f not in unverified]

    def label(f):
        return "確認の後に変わった" if stale(f) else (status(f) or "まだ")
    sections = (("NG", ng),
                ("確認が要る（新しい確認の AI に読ませる）", [f"{f['id']} [{label(f)}] {f['claim']}" for f in todo]),
                ("無いことの主張で、検索が無い（読んだ範囲で確認）", [f"{f['id']} {f['claim']}" for f in read_only]),
                ("未確認", [f"{f['id']} {f['claim']}" for f in unverified]))
    for title, xs in sections:
        if xs:
            print(f"## {title}")
            print("\n".join(f"- {x}" for x in xs))
    print(f"\n事実 {len(facts)} / NG {len(ng)} / 確認が要る {len(todo)} / 未確認 {len(unverified)}")
    sys.exit(1 if ng else 0)


if __name__ == "__main__":
    main()
