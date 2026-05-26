return {
	"rachartier/tiny-code-action.nvim",
	opts = {},
	keys = {
		{
			"gra",
			mode = "n",
			desc = "Code actions",
			function()
				require("tiny-code-action").code_action()
			end,
		},
		{
			"<C-.>",
			mode = { "n", "i" },
			desc = "Code actions",
			function()
				require("tiny-code-action").code_action()
			end,
		},
	},
}
