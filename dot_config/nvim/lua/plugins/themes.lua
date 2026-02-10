return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
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
		priority = 1000,
		opts = {
			background = "hard",
			transparent_background_level = vim.g.transparent and 2 or 0,
		},
	},
	{
		"mellow-theme/mellow.nvim",
		priority = 1000,
		config = function()
			vim.g.mellow_transparent = vim.g.transparent
		end,
	},
	{
		"bluz71/vim-moonfly-colors",
		name = "moonfly",
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
