vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.swapfile = false
vim.opt.splitright = true
vim.opt.cursorline = false
vim.opt.wrap = false
vim.opt.number = true
vim.opt.relativenumber = true

vim.diagnostic.enable = true
vim.diagnostic.config({ virtual_text = true })

vim.g.editorconfig = true
vim.g.mapleader = " "

vim.cmd("colorscheme catppuccin")
