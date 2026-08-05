#!/usr/bin/env python3
"""annotate スキルの出力HTMLを機械検証する。
usage: check.py <output.html> <target_source_file...>
- マーカー ⟦id⟧...⟦⟧ の id 集合と meta JSON の ann キー集合の一致
- ネストや閉じ忘れの検出
- マーカーを除去したソースが対象ファイルの原文と一致するか
  （複数ファイル時は ⟪path⟫ 区切りのチャンクを引数の順に突き合わせる）
"""
import json
import re
import sys

OPEN = re.compile(r"⟦([A-Za-z0-9_-]+)⟧")
ANY = re.compile(r"⟦[A-Za-z0-9_-]*⟧")

def main() -> int:
    out_path, target_paths = sys.argv[1], sys.argv[2:]
    html = open(out_path, encoding="utf-8").read()

    m = re.search(r'<script type="text/plain" id="src">(.*?)</script>', html, re.S)
    if not m:
        print("NG: #src ブロックが見つからない")
        return 1
    src = m.group(1)

    m = re.search(r'<script type="application/json" id="meta">(.*?)</script>', html, re.S)
    if not m:
        print("NG: #meta ブロックが見つからない")
        return 1
    try:
        meta = json.loads(m.group(1))
    except json.JSONDecodeError as e:
        print(f"NG: meta JSON が不正: {e}")
        return 1

    ok = True

    # マーカーの整合 (開き→閉じの交互出現)
    depth = 0
    for tok in ANY.finditer(src):
        is_open = tok.group(0) != "⟦⟧"
        depth += 1 if is_open else -1
        if depth not in (0, 1):
            print(f"NG: マーカーのネストまたは閉じ忘れ: {src[max(0,tok.start()-40):tok.end()+10]!r}")
            ok = False
            break
    if depth != 0:
        print("NG: 開きマーカーと閉じマーカーの数が合わない")
        ok = False

    used = set(OPEN.findall(src))
    defined = set(meta.get("ann", {}))
    if used - defined:
        print(f"NG: ann に定義がないマーカー id: {sorted(used - defined)}")
        ok = False
    if defined - used:
        print(f"NG: マーカーで使われていない ann キー: {sorted(defined - used)}")
        ok = False

    # 原文一致 (マーカー除去後)。⟪path⟫ 区切りで複数ファイルに対応
    clean = ANY.sub("", src).strip("\n")
    chunks = []
    cur = []
    for line in clean.split("\n"):
        if re.fullmatch(r"⟪.+⟫", line):
            if cur:
                chunks.append("\n".join(cur).strip("\n"))
            cur = []
        else:
            cur.append(line)
    chunks.append("\n".join(cur).strip("\n"))
    chunks = [c for c in chunks if c]
    if len(chunks) != len(target_paths):
        print(f"NG: ファイル数不一致 出力チャンク={len(chunks)} 対象ファイル={len(target_paths)}")
        ok = False
    for chunk, target_path in zip(chunks, target_paths):
        orig = open(target_path, encoding="utf-8").read().strip("\n")
        if chunk == orig:
            continue
        ok = False
        chunk_lines, orig_lines = chunk.split("\n"), orig.split("\n")
        if len(chunk_lines) != len(orig_lines):
            print(f"NG: {target_path} 行数不一致 出力={len(chunk_lines)} 原文={len(orig_lines)}")
        for i, (c, o) in enumerate(zip(chunk_lines, orig_lines), 1):
            if c != o:
                print(f"NG: {target_path} と不一致 (最初の相違: {i}行目)\n  出力: {c!r}\n  原文: {o!r}")
                break

    # レベル値の妥当性
    for key, a in meta.get("ann", {}).items():
        if a.get("lv") not in (1, 2):
            print(f"NG: ann[{key}].lv は 1 か 2: {a.get('lv')!r}")
            ok = False

    print("OK: マーカー・meta・原文すべて整合" if ok else "検証NGあり (上記を修正)")
    return 0 if ok else 1

if __name__ == "__main__":
    sys.exit(main())
