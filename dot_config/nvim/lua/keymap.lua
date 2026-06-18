-- Utility functions
function set_textobject_keymap(keymap, selection)
	vim.keymap.set("v", keymap, function()
		require("nvim-treesitter-textobjects.select").select_textobject(selection, "textobjects")
	end)
end

-- Textobjects
set_textobject_keymap("af", "@function.outer")
set_textobject_keymap("if", "@function.inner")
set_textobject_keymap("ac", "@class.outer")
set_textobject_keymap("ic", "@class.inner")
set_textobject_keymap("as", "@local.scope")

-- Telescope
local ts = require("telescope.builtin")
vim.keymap.set("n", "<leader>f", ts.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>g", ts.live_grep, { desc = "Telescope live grep" })
vim.keymap.set("n", "<leader>b", ts.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>tds", "<CMD>TodoTelescope<CR>")

-- Normify
vim.keymap.set("n", "<C-Tab>", ":bnext<CR>")
vim.keymap.set("n", "<C-S-Tab>", ":bprevious<CR>")
vim.keymap.set("n", "<C-s>", "<cmd>w<cr>", { silent = true })
vim.keymap.set("i", "<C-s>", "<esc><cmd>w<cr>a", { silent = true })
vim.keymap.set("i", "<C-BS>", "<C-w>")

-- Navigation
vim.keymap.set("n", "<A-l>", ":bnext<CR>")
vim.keymap.set("n", "<A-h>", ":bprevious<CR>")
vim.keymap.set("n", "<leader>p", "<CMD>Oil<CR>")
vim.keymap.set("n", "grd", vim.lsp.buf.definition, { desc = "go to definitions" })
vim.keymap.set("n", "s", function()
	require("flash").jump()
end)

-- Other
vim.keymap.set("n", "<C-q>", ":bd<CR>", { desc = "Close buffer" })
vim.keymap.set("n", "<C-l>", "<CMD>edit!<CR>", { desc = "Reload buffer from disk" })
