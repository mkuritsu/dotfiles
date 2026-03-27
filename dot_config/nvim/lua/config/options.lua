vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.wrap = false
vim.opt.scrolloff = 10
vim.opt.swapfile = false
vim.opt.clipboard = "unnamedplus"
vim.opt.splitright = true
vim.opt.cursorline = true
vim.opt.termguicolors = true

vim.diagnostic.enable = true
vim.diagnostic.config({ virtual_text = true })

vim.g.editorconfig = true
vim.g.default_colorscheme = "catppuccin"
vim.g.colorscheme_storage = vim.fn.stdpath("cache") .. "/last_colorscheme"
vim.g.transparent = false
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
