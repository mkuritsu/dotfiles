return {
	"folke/todo-comments.nvim",
	event = "VeryLazy",
	opts = {},
	keys = {
		{
			"<leader>td",
			function()
				Snacks.picker.todo_comments()
			end,
			desc = "TODO list",
		},
	},
}
