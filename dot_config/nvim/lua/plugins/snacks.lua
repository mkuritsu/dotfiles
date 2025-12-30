return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		explorer = { enabled = true },
		picker = { enabled = true },
		indent = { enabled = true },
		notifier = { enabled = true },
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
		{
			"<leader>e",
			mode = "n",
			desc = "Explorer",
			function()
				Snacks.explorer()
			end,
		},
	},
}
