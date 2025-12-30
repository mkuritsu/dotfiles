return {
	"rachartier/tiny-code-action.nvim",
	opts = {},
	keys = {
		{
			"<leader>ca",
			mode = "n",
			desc = "Code actions",
			function()
				require("tiny-code-action").code_action()
			end,
		},
	},
}
