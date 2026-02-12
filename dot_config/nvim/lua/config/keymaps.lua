vim.keymap.set("i", "<C-h>", "<left>")
vim.keymap.set("i", "<C-j>", "<down>")
vim.keymap.set("i", "<C-k>", "<up>")
vim.keymap.set("i", "<C-l>", "<right>")

vim.keymap.set("n", "<leader>q", ":bd<CR>", { desc = "Close buffer" })

vim.keymap.set("n", "<leader>p", "<CMD>Oil<CR>", { desc = "Open parent directory" })

vim.keymap.set("n", "grd", function()
	vim.lsp.buf.definition()
end, { desc = "go to definitions" })

vim.keymap.set("n", "<leader>m", "<CMD>MaximizerToggle!<CR>", { desc = "toggle maximize" })
