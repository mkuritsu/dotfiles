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

vim.g.editorconfig = true

vim.diagnostic.config({ virtual_text = true })
vim.diagnostic.enable = true

vim.cmd.colorscheme("catppuccin")
