return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {},
  keys = {
    { "<leader>s", mode = {"n", "x", "o"}, function() require("flash").jump() end, desc = "Flash" }
  }
}
