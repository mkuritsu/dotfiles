return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
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
            "<C-`>",
            mode = {"n", "t"},
            desc = "Toggle terminal",
            function()
                Snacks.terminal()
            end
        },
        {
            "<leader>p",
            mode = "n",
            desc = "Projects",
            function()
                local opts = { dev = {"~/Dev", "~/Projects"}}
                Snacks.picker.projects(opts)
            end
        }
	},
}
