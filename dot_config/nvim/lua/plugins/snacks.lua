return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		picker = { enabled = true },
		indent = { enabled = true },
		notifier = { enabled = true },
		explorer = { enabled = false },
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
			"<C-`>",
			mode = { "n", "t" },
			desc = "Toggle terminal",
			function()
				Snacks.terminal()
			end,
		},
		{
			"<leader>p",
			mode = "n",
			desc = "Projects",
			function()
				local opts = { dev = { "~/Dev", "~/Projects" } }
				Snacks.picker.projects(opts)
			end,
		},
		{
			"<C-b>",
			mode = { "n", "i" },
			desc = "Toggle file tree",
			function()
				Snacks.explorer()
			end,
		},
	},
}
