return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			local ts = require("nvim-treesitter")
			ts.install("all")
			-- ts.install({
			-- 	"rust",
			-- 	"c",
			-- 	"cpp",
			-- 	"java",
			-- 	"lua",
			-- 	"python",
			-- 	"javascript",
			-- 	"typescript",
			-- 	"css",
			-- 	"html",
			-- 	"sql",
			-- 	"astro",
			-- 	"nix",
			-- 	"bash",
			-- 	"fish",
			-- 	"hyprlang",
			-- 	"markdown",
			-- 	"json",
			-- 	"yaml",
			-- 	"toml",
			-- 	"kdl",
			-- 	"latex",
			-- 	"typst",
			-- })
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		init = function()
			vim.g.no_plugin_maps = true
		end,
		config = function()
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
		end,
		keys = {
			{
				"af",
				mode = "v",
				desc = "Select @function.outer",
				function()
					require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
				end,
			},
			{
				"if",
				mode = "v",
				desc = "Select @function.inner",
				function()
					require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
				end,
			},
			{
				"ac",
				mode = "v",
				desc = "Select @function.inner",
				function()
					require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects")
				end,
			},
			{
				"ic",
				mode = "v",
				desc = "Select @function.inner",
				function()
					require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects")
				end,
			},
		},
	},
}
