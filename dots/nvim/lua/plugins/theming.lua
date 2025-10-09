return {
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = {
      transparent = false,
      style = "moon",
      styles = {
        comments = { italic = false },
        keywords = { italic = false }
      }
    },
  },

  {
    "catppuccin/nvim",
    name = "catppuccin-nvim",
    lazy = true,
    config = function()
      require("catppuccin").setup {
        flavour = "mocha",
        transparent_background = vim.env.XDG_CURRENT_DESKTOP == "Hyprland",
        float = {
          solid = false,
          transparent = true
        },
        no_italic = true,
        auto_integrations = true,
        integrations = {
          blink_cmp = {
            enabled = true,
            style = "bordered"
          },
          flash = true,
          treesitter = true,
          snacks = {
            enabled = true
          },
          which_key = true
        }
      }
    end
  }
}
