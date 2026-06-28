-- Utility functions
local function set_textobject_keymap(keymap, selection)
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

-- Snacks picker
vim.keymap.set("n", "<leader>f", function()
	Snacks.picker.files()
end, { desc = "Find files" })
vim.keymap.set("n", "<leader>g", function()
	Snacks.picker.grep()
end, { desc = "Live grep" })
vim.keymap.set("n", "<leader>b", function()
	Snacks.picker.buffers()
end, { desc = "Buffers" })
vim.keymap.set("n", "<leader>tds", function()
	Snacks.picker.grep({ pattern = "TODO|FIXME|HACK|WARN|PERF|NOTE" })
end, { desc = "Todo comments" })

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
