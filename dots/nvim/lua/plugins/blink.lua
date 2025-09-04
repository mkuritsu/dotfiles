return {
  "saghen/blink.cmp",
  event = "VeryLazy",
  build = "cargo build --release",
  opts = {
    keymap = {
      preset = "enter",
      ["<C-k>"] = false,
      ['<C-y>'] = { 'show_signature', 'hide_signature', 'fallback' },
    },
    appearance = {
      nerd_font_variant = 'mono'
    },
    signature = {
      enabled = true
    },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 200
    },
    completion = {
      list = { selection = { auto_insert = false } },
      ghost_text = {
        enabled = true,
        show_with_menu = true
      }
    },
  }
}
