vim.keymap.set("i", "<C-h>", "<left>")
vim.keymap.set("i", "<C-j>", "<down>")
vim.keymap.set("i", "<C-k>", "<up>")
vim.keymap.set("i", "<C-l>", "<right>")

vim.keymap.set("n", "<C-q>", ":bd<CR>", { desc = "Close buffer" })

vim.keymap.set("n", "<leader>-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
vim.keymap.set("n", "<C-l>", "<CMD>edit!<CR>", { desc = "Reload buffer from disk" })

vim.keymap.set("n", "grd", function()
	vim.lsp.buf.definition()
end, { desc = "go to definitions" })

vim.keymap.set("n", "<S-l>", ":bnext<CR>")
vim.keymap.set("n", "<S-h>", ":bprevious<CR>")
vim.keymap.set("n", "<C-Tab>", ":bnext<CR>")
vim.keymap.set("n", "<C-S-Tab>", ":bprevious<CR>")
