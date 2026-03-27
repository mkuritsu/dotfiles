return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
        lazy = false,
		priority = 1000,
		opts = {
			flavour = "mocha",
			transparent_background = vim.g.transparent,
			no_italic = true,
		},
	},
	{
		"rebelot/kanagawa.nvim",
		name = "kanagawa",
        lazy = false,
		priority = 1000,
		opts = {
			commentStyle = { italic = false },
			keywordStyle = { italic = false },
			transparent = vim.g.transparent,
		},
	},
	{
		"rose-pine/neovim",
		name = "rose-pine",
        lazy = false,
		priority = 1000,
		opts = {
			variant = "main",
			dim_inactive_windows = true,
			styles = { italic = false, transparency = vim.g.transparent },
		},
	},
	{
		"neanias/everforest-nvim",
		name = "everforest",
        lazy = false,
		priority = 1000,
		opts = {
			background = "hard",
			transparent_background_level = vim.g.transparent and 2 or 0,
		},
	},
	{
		"mellow-theme/mellow.nvim",
        lazy = false,
		priority = 1000,
		config = function()
			vim.g.mellow_transparent = vim.g.transparent
		end,
	},
	{
		"bluz71/vim-moonfly-colors",
		name = "moonfly",
        lazy = false,
		priority = 1000,
		config = function()
			vim.g.moonflyItalics = false
			vim.g.moonflyTransparent = vim.g.transparent
		end,
	},
	{
		"projekt0n/github-nvim-theme",
		name = "github-theme",
		lazy = false,
		priority = 1000,
		opts = {
			options = {
				transparent = vim.g.transparent,
			},
		},
	},
	{
		"astronvim/astrotheme",
		opts = {
			style = {
				transparent = vim.g.transparent,
			},
		},
	},
}
