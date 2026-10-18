vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.swapfile = false
vim.opt.splitright = true
vim.opt.wrap = false
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true

vim.diagnostic.config({ virtual_text = true })

vim.g.editorconfig = true
vim.g.mapleader = " "

pcall(vim.cmd.colorscheme, "catppuccin")
