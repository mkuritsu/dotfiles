local LAST_COLORSCHEME_FILE = vim.fn.stdpath("cache") .. "/last_colorscheme"

vim.api.nvim_create_autocmd("BufWritePre", {
	callback = function(event)
		require("conform").format({ bufnr = event.buf })
	end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		vim.fn.mkdir(vim.fn.stdpath("cache"), "p")
		vim.fn.writefile({ vim.g.colors_name }, LAST_COLORSCHEME_FILE)
	end,
})

local colorscheme = vim.g.colorscheme
if vim.fn.filereadable(LAST_COLORSCHEME_FILE) == 1 then
	colorscheme = vim.fn.readfile(LAST_COLORSCHEME_FILE)[1]
end
vim.cmd.colorscheme(colorscheme)
