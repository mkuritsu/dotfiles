return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    lazy = false,
    opts = {
      filesystem = {
        group_empty_dirs = true
      }
    },
    keys = {
      {
        "<leader>d",
        function()
          vim.cmd("Neotree toggle")
        end
      }
    }
  },
}
