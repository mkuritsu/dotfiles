require("config.options")
require("config.keymaps")

if mnw ~= nil then
  require("lazy").setup({
    dev = {
      path = mnw.configDir .. "/pack/mnw/opt",
      patterns = { "" },
      fallback = true,
    },

    performance = {
      reset_packpath = false,
      rtp = {
        reset = false,
      },
    },

    install = {
      missing = true,
    },

    spec = {
      { import = "plugins" },
    },
  })
else
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
      vim.api.nvim_echo({
        { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
        { out,                            "WarningMsg" },
        { "\nPress any key to exit..." },
      }, true, {})
      vim.fn.getchar()
      os.exit(1)
    end
  end
  vim.opt.rtp:prepend(lazypath)

  require("lazy").setup({
    spec = {
      { import = "plugins" },
    },
    checker = { enabled = true },
  })
end

require("config.misc")


if vim.env.PROF then
  print("Profiling...")
  -- example for lazy.nvim
  -- change this to the correct path for your plugin manager
  local snacks = vim.fn.stdpath("data") .. "/lazy/snacks.nvim"
  vim.opt.rtp:append(snacks)
  require("snacks.profiler").startup({
    startup = {
      event = "VimEnter", -- stop profiler on this event. Defaults to `VimEnter`
      -- event = "UIEnter",
      -- event = "VeryLazy",
    },
  })
end
