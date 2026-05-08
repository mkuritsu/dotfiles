require("config.options")
require("config.lazy")
require("config.keymaps")
require("config.autocmds")

local colorscheme = "catppuccin"
if vim.fn.filereadable(vim.g.colorscheme_storage) == 1 then
	colorscheme = vim.fn.readfile(vim.g.colorscheme_storage)[1]
end
vim.cmd.colorscheme(colorscheme)
