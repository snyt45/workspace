-- 整形（複数行）JSONの comments.json が読めること
-- （vim.fn.readfile は行ごとに返すため、連結してデコードする必要がある）
H.run(function()
	vim.fn.writefile({
		"{",
		'  "description": "test",',
		'  "commit": "0000000000000000000000000000000000000000",',
		'  "steps": [',
		"    {",
		'      "file": "init.lua",',
		'      "line": 6,',
		'      "thread": [',
		'        { "author": "you", "text": "hello" },',
		'        { "author": "pi", "text": "reply" }',
		"      ]",
		"    }",
		"  ]",
		"}",
	}, H.json)

	H.setup()

	local s = H.session()
	assert(s, "pi-comments not created")
	assert(s.total == 1, "expected 1 step from multiline json, got " .. s.total)
end)
