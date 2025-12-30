vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.keymap.set("i", "<C-h>", "<left>")
vim.keymap.set("i", "<C-j>", "<down>")
vim.keymap.set("i", "<C-k>", "<up>")
vim.keymap.set("i", "<C-l>", "<right>")

vim.keymap.set("n", "<leader>q", ":bd<CR>", { desc = "Close buffer" })
