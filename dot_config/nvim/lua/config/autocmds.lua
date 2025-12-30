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
