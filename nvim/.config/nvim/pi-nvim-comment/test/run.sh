#!/usr/bin/env bash
# pi-nvim-comment / walkthrough.nvim のheadlessテストを全部走らせる。
#   ./test/run.sh            すべて
#   ./test/run.sh smoke      名前に smoke を含むものだけ
#
# 各テストは専用の一時プロジェクト（init.lua + .walkthroughs/comments.json）と
# 専用の XDG_STATE_HOME で動くので、実環境の未提出コメントには触らない。
set -uo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILTER="${1:-}"

fixture() {
	local dir="$1"
	mkdir -p "$dir/.walkthroughs"
	cat >"$dir/init.lua" <<'LUA'
-- fixture
local M = {}
function M.setup()
	M.ready = true
end
function M.run()
	return M.ready
end
return M
LUA
	cat >"$dir/.walkthroughs/comments.json" <<'JSON'
{
  "description": "test",
  "commit": "0000000000000000000000000000000000000000",
  "steps": [
    {
      "file": "init.lua",
      "line": 6,
      "thread": [
        { "author": "you", "text": "hello" },
        { "author": "pi", "text": "reply" }
      ]
    }
  ]
}
JSON
}

pass=0
fail=0
failed_names=()

for test_file in "$TEST_DIR"/*.lua; do
	name="$(basename "$test_file" .lua)"
	[[ "$name" == "helper" ]] && continue
	[[ -n "$FILTER" && "$name" != *"$FILTER"* ]] && continue

	work="$(mktemp -d)"
	project="$work/project"
	mkdir -p "$project" "$work/state"
	fixture "$project"

	output="$(
		cd "$project" &&
			PI_TEST_DIR="$(cd "$project" && pwd -P)" \
				XDG_STATE_HOME="$work/state" \
				nvim --headless -u NONE -i NONE \
				-c "luafile $TEST_DIR/helper.lua" \
				-c "luafile $test_file" 2>&1
	)"

	if grep -q "^RESULT: OK" <<<"$output"; then
		printf '  ok   %s\n' "$name"
		pass=$((pass + 1))
	else
		printf '  FAIL %s\n' "$name"
		sed 's/^/       /' <<<"$output"
		fail=$((fail + 1))
		failed_names+=("$name")
	fi
	rm -rf "$work"
done

echo
if ((fail == 0)); then
	echo "all passed ($pass)"
else
	echo "failed: ${failed_names[*]} ($fail/$((pass + fail)))"
fi
exit $((fail > 0 ? 1 : 0))
