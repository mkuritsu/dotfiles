return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = true,
		priority = 1000,
		opts = {
			flavour = "mocha",
			transparent_background = true,
			no_italic = true,
		},
	},
	{
		"rebelot/kanagawa.nvim",
		name = "kanagawa",
		lazy = true,
		opts = {
			commentStyle = { italic = false },
			keywordStyle = { italic = false },
			transparent = true,
		},
	},
	{
		"rose-pine/neovim",
		name = "rose-pine",
		lazy = true,
		opts = {
			variant = "main",
			dim_inactive_windows = true,
			styles = { italic = false, transparency = true },
		},
	},
}
