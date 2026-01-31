return {
	"neovim/nvim-lspconfig",
	config = function()
		vim.lsp.enable({
			"rust_analyzer",
			"clangd",
			"jdtls",
			"nil_ls",
			"lua_ls",
			"basedpyright",
			"ruff",
			"astro",
			"ts_ls",
			"html",
			"cssls",
			"tailwindcss",
			"jsonls",
		})
	end,
}
