return {
	"stevearc/oil.nvim",
	lazy = false,
	opts = {
		float = {
			border = "rounded",
			padding = 2,
		},
		view_options = {
			show_hidden = true,
		},
	},
	keys = {
		{
			"<leader>o",
			function()
				require("oil").open_float()
			end,
			desc = "Open Oil floating",
		},
	},
}
