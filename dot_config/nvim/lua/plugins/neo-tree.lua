return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		"nvim-tree/nvim-web-devicons",
	},
	priority = 100,
	lazy = false,
	opts = {
		close_if_last_window = true,
		window = {
			width = 25,
			mappings = {
				["<C-b>"] = "close_window",
				["l"] = "open",
				["h"] = "close_node",
			},
		},
		filesystem = {
			hijack_netrw_behavior = "open_default",
			follow_current_file = { enabled = true },
		},
	},
	keys = {
		{
			"<C-b>",
			mode = { "n", "i" },
			desc = "Toggle file tree",
			function()
				require("neo-tree.command").execute({ reveal = true })
			end,
		},
	},
}
