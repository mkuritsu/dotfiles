return {
	"akinsho/bufferline.nvim",
	version = "*",
	dependencies = "nvim-tree/nvim-web-devicons",
	config = function()
		require("bufferline").setup({
			options = {
				offsets = {
					{
						filetype = "neo-tree",
						separator = false,
						text = "File Tree",
						text_align = "left",
					},
				},
			},
		})
	end,
}
