local js_formatters = { "biome", "prettierd", "prettier", stop_after_first = true }

return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>lf",
			function()
				require("conform").format({ async = true })
			end,
			mode = "n",
			desc = "Format buffer",
		},
	},
	opts = {
		formatters_by_ft = {
			typescript = js_formatters,
			typescriptreact = js_formatters,
			javascript = js_formatters,
			javascriptreact = js_formatters,
			astro = js_formatters,
			cpp = { "clang-format" },
			c = { "clang-format" },
			lua = { "stylua" },
			nix = { "alejandra" },
		},
		default_format_opts = {
			lsp_format = "fallback",
		},
		format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
	},
	init = function()
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
}
