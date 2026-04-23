return {
	"folke/sidekick.nvim",
	dependencies = { "folke/snacks.nvim" },
	event = "VeryLazy",
	-- WORKAROUND: https://github.com/folke/sidekick.nvim/issues/276
	-- Copilot LSP が同期応答するケースで _requests 登録前に handler が走り、
	-- 応答が stale 判定で破棄されて NES 提案が出ない regression があるため、
	-- generation ベースで順序を補正する monkey-patch を当てている。
	-- folke 側で修正されたら opts を通常の table に戻す。
	opts = function(_, opts)
		opts.cli = vim.tbl_deep_extend("force", opts.cli or {}, {
			win = {
				layout = "float",
				keys = {
					stopinsert  = false,
					hide_ctrl_q = { "<c-q>", "hide", mode = "nt" },
				},
			},
		})

		local Config = require("sidekick.config")
		local Nes = require("sidekick.nes")

		if not Nes._sync_safe_update_patched then
			Nes._sync_safe_update_patched = true
			Nes._request_generation = {}

			local handler = Nes._handler
			Nes._handler = function(err, res, ctx)
				if not ctx or not ctx.client_id then
					return
				end
				local generation = ctx._sidekick_generation
				if generation and Nes._request_generation[ctx.client_id] ~= generation then
					return
				end
				if ctx.request_id then
					Nes._requests[ctx.client_id] = ctx.request_id
				end
				return handler(err, res, ctx)
			end

			Nes.update = function()
				local buf = vim.api.nvim_get_current_buf()
				Nes.clear()

				local enabled = Nes.enabled and Config.nes.enabled or false
				if not (vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf)) then
					return
				end
				if type(enabled) == "function" then
					enabled = enabled(buf) or false
				else
					enabled = enabled ~= false
				end
				if not enabled then
					return
				end

				local client = Config.get_client(buf)
				if not client then
					return
				end

				local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
				params.textDocument.version = vim.lsp.util.buf_versions[buf]
				params.context = { triggerKind = 2 }

				local generation = (Nes._request_generation[client.id] or 0) + 1
				Nes._request_generation[client.id] = generation

				local pending
				local request_id
				local ok
				ok, request_id = client:request(
					"textDocument/copilotInlineEdit",
					params,
					function(err, res, ctx)
						ctx = ctx or { client_id = client.id }
						ctx.client_id = ctx.client_id or client.id
						ctx.request_id = ctx.request_id or request_id
						ctx._sidekick_generation = generation

						if not request_id then
							pending = { err, res, ctx }
							return
						end

						Nes._handler(err, res, ctx)
					end
				)
				if ok and request_id then
					Nes._requests[client.id] = request_id
					if pending then
						pending[3].request_id = pending[3].request_id or request_id
						vim.schedule(function() Nes._handler(pending[1], pending[2], pending[3]) end)
					end
				end
			end
		end

		return opts
	end,
	-- CLI統合機能 (OpenCode/Claude Code toggle 等) は不安定のため使わない方針。
	-- AIチャットは tmux 別pane の opencode/claude CLI alias (`c`/`cx`) で利用する。
	keys = {
		{
			"<tab>",
			function()
				if not require("sidekick").nes_jump_or_apply() then
					return "<Tab>"
				end
			end,
			expr = true,
			desc = "[Sidekick] NES: ジャンプ / 適用",
		},
	},
}
