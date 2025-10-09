vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd('BufWritePre', {
  callback = function()
    vim.lsp.buf.format({ timeout_ms = 1000 })
  end,
})

vim.diagnostic.config({ virtual_text = true })
vim.cmd.colorscheme "catppuccin"
