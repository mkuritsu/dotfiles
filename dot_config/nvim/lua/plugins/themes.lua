local transparent = false

return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = false,
		priority = 1000,
		opts = {
			flavour = "mocha",
			transparent_background = transparent,
			no_italic = true,
			auto_integrations = true,
			custom_highlights = function(colors)
				return {
					CursorLine = {
						bg = "NONE",
					},
					CursorLineNr = {
						fg = colors.mauve,
						bold = true,
					},
				}
			end,
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
			styles = { italic = false, transparency = transparent },
		},
	},
	{
		"projekt0n/github-nvim-theme",
		name = "github-theme",
		lazy = false,
		priority = 1000,
		opts = {
			options = {
				transparent = transparent,
			},
		},
	},
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			transparent = transparent,
		},
	},
}
