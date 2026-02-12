-- highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- change working directory when opening neovim with ("nvim <path>")
vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function(event)
		if event.file then
			local dir = event.file
			if vim.startswith(dir, "oil://") then
				dir = dir:sub(7)
			end
			if vim.fn.isdirectory(dir) == 0 then
				dir = vim.fn.fnamemodify(dir, ":h")
			end
			vim.cmd.cd(dir)
		end
	end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		vim.fn.mkdir(vim.fn.stdpath("cache"), "p")
		vim.fn.writefile({ vim.g.colors_name }, vim.g.colorscheme_storage)
	end,
})
