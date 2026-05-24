return {
	"akinsho/bufferline.nvim",
	version = "*",
	after = "catppuccin",
	dependencies = "nvim-tree/nvim-web-devicons",
	config = function()
		require("bufferline").setup({
			highlights = require("catppuccin.special.bufferline").get_theme(),
			options = {
				offsets = {
					{
						filetype = "neo-tree",
						separator = false,
						text = "Files",
						text_align = "left",
					},
					{
						filetype = "snacks_layout_box",
						separator = false,
						text = "Files",
						text_align = "left",
					},
				},
			},
		})
	end,
}
