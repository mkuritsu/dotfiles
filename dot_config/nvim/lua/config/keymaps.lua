vim.keymap.set("i", "<C-h>", "<left>")
vim.keymap.set("i", "<C-j>", "<down>")
vim.keymap.set("i", "<C-k>", "<up>")
vim.keymap.set("i", "<C-l>", "<right>")

vim.keymap.set("n", "<C-q>", ":bd<CR>", { desc = "Close buffer" })

vim.keymap.set("n", "<C-l>", "<CMD>edit!<CR>", { desc = "Reload buffer from disk" })

vim.keymap.set("n", "grd", vim.lsp.buf.definition, { desc = "go to definitions" })

vim.keymap.set("n", "<S-l>", ":bnext<CR>")
vim.keymap.set("n", "<S-h>", ":bprevious<CR>")
vim.keymap.set("n", "<C-Tab>", ":bnext<CR>")
vim.keymap.set("n", "<C-S-Tab>", ":bprevious<CR>")

vim.keymap.set("n", "<C-s>", "<cmd>w<cr>", { silent = true })
vim.keymap.set("i", "<C-s>", "<esc><cmd>w<cr>a", { silent = true })

vim.keymap.set("i", "<C-BS>", "<C-w>")
