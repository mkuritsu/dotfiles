return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		"nvim-tree/nvim-web-devicons",
	},
	lazy = false,
	opts = {
		window = {
			width = 25,
			mappings = {
				["<C-b>"] = "close_window",
				["l"] = "open",
				["h"] = "close_node",
			},
		},
	},
	keys = {
		{
			"<C-b>",
			mode = { "n", "i" },
			desc = "Toggle file tree",
			function()
				require("neo-tree.command").execute({ toggle = true })
			end,
		},
	},
}
