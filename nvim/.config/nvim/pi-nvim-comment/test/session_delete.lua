-- ,wo の削除アクション（ops.delete_session）:
-- (1) 確認でNoなら何も消えない (2) Yesなら purge アクションが走り実データごと消える
H.run(function()
	H.setup()
	local ops = require("walkthrough.ops")
	local sessions = require("walkthrough.session")

	local answer = 2 -- No
	local asked = 0
	local real_confirm = vim.fn.confirm
	vim.fn.confirm = function()
		asked = asked + 1
		return answer
	end

	local session = sessions.find("pi-comments")
	assert(session, "pi-comments not found")

	assert(ops.delete_session(session) == false, "No should cancel the deletion")
	assert(asked == 1, "delete must ask for confirmation")
	assert(vim.fn.filereadable(H.json) == 1, "thread file must survive a cancelled deletion")
	assert(H.session(), "session must survive a cancelled deletion")

	answer = 1 -- Yes
	assert(ops.delete_session(session), "Yes should delete")
	assert(vim.fn.filereadable(H.json) == 0, "thread file should be deleted by purge")
	assert(not H.session(), "session should be gone")

	vim.fn.confirm = real_confirm
end)
