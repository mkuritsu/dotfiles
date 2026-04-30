return {
	{
		"mason-org/mason.nvim",
		opts = {},
	},
	{
		"mason-org/mason-lspconfig.nvim",
		dependencies = {
			"neovim/nvim-lspconfig",
		},
		opts = {
			ensure_installed = {
				"stylua",
				"ts_ls",
				"html",
				"oxfmt",
				"oxlint",
				"tailwindcss",
				"basedpyright",
				"jdtls",
				"nil_ls",
				"astro",
				"bashls",
				"cssls",
				"yamlls",
				"jsonls",
				"dockerls",
				"ruff",
				"lua_ls",
			},
		},
	},
}
