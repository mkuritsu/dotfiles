return {
	"neovim/nvim-lspconfig",
	config = function()
		vim.lsp.enable({ "basedpyright", "rust_analyzer", "clangd", "jdtls", "ruff", "nil_ls", "emmylua_ls" })
	end,
}
