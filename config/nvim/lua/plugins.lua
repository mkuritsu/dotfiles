vim.pack.add({
	-- LSPs, highlithing, suggestions, etc...
	{ src = "https://github.com/folke/lazydev.nvim" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/mason-org/mason.nvim" },
	{ src = "https://github.com/mason-org/mason-lspconfig.nvim" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
	{ src = "https://github.com/saghen/blink.cmp", version = "v1" },
	{ src = "https://github.com/stevearc/conform.nvim" },

	-- Style/UI
	{ src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
	{ src = "https://github.com/nvim-lualine/lualine.nvim" },
	{ src = "https://github.com/nvim-tree/nvim-web-devicons" },
	{ src = "https://github.com/j-hui/fidget.nvim" },

	-- Utils
	{ src = "https://github.com/folke/todo-comments.nvim" },
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
	{ src = "https://github.com/windwp/nvim-autopairs" },
	{ src = "https://github.com/windwp/nvim-ts-autotag" },

	-- Navigation
	{ src = "https://github.com/folke/snacks.nvim" },
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/folke/flash.nvim" },

	-- Dependency
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
})

-- LSP/highlithing/formatting
local grammars =
	{ "lua", "rust", "c", "cpp", "java", "python", "bash", "fish", "nix", "json", "yaml", "just", "dockerfile", "toml" }

local lsps = {
	-- C/C++
	"clangd",
	-- "clang-format",

	-- Rust
	-- "rust-analyzer",

	-- Lua
	"stylua",
	"lua_ls",

	-- JS/TS
	"ts_ls",
	"oxfmt",
	"oxlint",
	"tailwindcss",
	"html",
	"astro",
	"cssls",

	-- Python
	"basedpyright",
	"ruff",

	-- Java
	"jdtls",

	-- Go
	"gopls",

	-- Zig
	"zls",

	-- Misc
	"bashls",
	"yamlls",
	"jsonls",
	"dockerls",
}

vim.lsp.enable("clangd")
vim.lsp.enable("rust-analyzer")

require("nvim-treesitter").install(grammars)
require("nvim-treesitter-textobjects").setup({
	select = {
		lookahead = true,
		selection_modes = {
			["@parameter.outer"] = "v",
			["@function.outer"] = "V",
			["@class.outer"] = "<c-v>",
		},
		include_surrounding_whitespace = false,
	},
})

require("mason").setup()
require("mason-lspconfig").setup({
	ensure_installed = lsps,
})

require("lazydev").setup({
	library = {
		{ path = "luvit-meta/library", words = { "vim%.uv" } },
	},
})

local js_formatters = { "oxfmt", "biome", "prettierd", "prettier", stop_after_first = true }
require("conform").setup({
	formatters_by_ft = {
		typescript = js_formatters,
		typescriptreact = js_formatters,
		javascript = js_formatters,
		javascriptreact = js_formatters,
		astro = js_formatters,
		json = js_formatters,
		cpp = { "clang-format" },
		c = { "clang-format" },
		lua = { "stylua" },
		nix = { "alejandra" },
	},
	default_format_opts = {
		lsp_format = "fallback",
	},
	format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
})

-- Suggestions
require("blink.cmp").setup({
	keymap = {
		preset = "enter",
		["<Tab>"] = { "accept", "fallback" },
	},
})

-- Navigation
require("snacks").setup({
	picker = {
		sources = {
			files = { follow = true },
			grep = { follow = true },
		},
	},
})
require("oil").setup({
	default_file_explorer = true,
	view_options = {
		show_hidden = true,
	},
})

require("nvim-autopairs").setup({
	check_ts = true,
})

-- UI
require("todo-comments").setup({
	signs = false,
})

require("gitsigns").setup({
	current_line_blame = true,
	current_line_blame_opts = {
		delay = 0,
	},
})

require("lualine").setup({
	options = {
		globalstatus = true,
		component_separators = "",
		section_separators = { left = "", right = "" },
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch" },
		lualine_c = { "filename" },
		lualine_x = { "encoding", "fileformat", "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
})

require("fidget").setup({})

require("catppuccin").setup({
	flavour = "macchiato",
	transparent_background = false,
	float = {
		transparent = true,
	},
})
