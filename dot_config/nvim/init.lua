require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")

local colorscheme = vim.g.default_colorscheme
if vim.fn.filereadable(vim.g.colorscheme_storage) == 1 then
	colorscheme = vim.fn.readfile(vim.g.colorscheme_storage)[1]
end
vim.cmd.colorscheme(colorscheme)
