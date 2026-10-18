local ok, err = pcall(vim.pack.add, {
    -- Style/UI
    { src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
    { src = "https://github.com/nvim-lualine/lualine.nvim" },
    { src = "https://github.com/nvim-tree/nvim-web-devicons" },

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
if not ok then
    vim.notify("vim.pack.add failed: " .. tostring(err), vim.log.levels.WARN)
end

-- Call `require(name).setup(opts)` only if the plugin is installed
local function setup(name, opts)
    local has_plugin, plugin = pcall(require, name)
    if has_plugin then
        plugin.setup(opts)
    end
end

-- Navigation
setup("snacks", {
    picker = {
        sources = {
            files = { follow = true },
            grep = { follow = true },
        },
    },
})

setup("oil", {
    default_file_explorer = true,
    view_options = {
        show_hidden = true,
    },
})

setup("nvim-autopairs", {
    check_ts = true,
})

-- UI
setup("todo-comments", {
    signs = false,
})

setup("gitsigns", {
    current_line_blame = true,
    current_line_blame_opts = {
        delay = 0,
    },
})

setup("lualine", {
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

setup("catppuccin", {
    flavour = "macchiato",
    transparent_background = false,
    float = {
        transparent = true,
    },
})
