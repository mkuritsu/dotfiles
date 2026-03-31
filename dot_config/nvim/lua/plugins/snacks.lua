return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		picker = { enabled = true },
		indent = { enabled = true },
		notifier = { enabled = true },

		explorer = { enabled = false },
		bigfile = { enabled = false },
		dashboard = { enabled = false },
		input = { enabled = false },
		quickfile = { enabled = false },
		scope = { enabled = false },
		scroll = { enabled = false },
		statuscolumn = { enabled = false },
		words = { enabled = false },
	},
	keys = {
		{
			"<leader>f",
			mode = "n",
			desc = "File picker",
			function()
				Snacks.picker.files()
			end,
		},
		{
			"<leader>g",
			mode = "n",
			desc = "Grep",
			function()
				Snacks.picker.grep()
			end,
		},
	},
}
