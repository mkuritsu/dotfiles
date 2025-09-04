{
  config,
  pkgs,
  lib,
  ...
}:
let
  sources = import ../npins;
  mnw = import sources.mnw;

  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  imports = [
    mnw.homeManagerModules.default
  ];

  home.sessionVariables.EDITOR = lib.mkOverride 900 "nvim";

  programs.mnw = {
    enable = true;
    luaFiles = [
      (mkOutOfStoreSymlink ../dots/nvim/init.lua)
    ];
    extraBinPath = with pkgs; [
      # tools
      fzf
      ripgrep
      fd

      # LSPs
      lua-language-server
      clang-tools
      basedpyright
      typescript-language-server
      rust-analyzer
      rustfmt
      clippy
      marksman
      nixd
      nixfmt-rfc-style
      alejandra
      jdt-language-server
      vscode-langservers-extracted # html,css,json
      astro-language-server
      prettier
      cmake-language-server
      ruff
    ];
    plugins = {
      start = with pkgs.vimPlugins; [
        lazy-nvim
      ];

      opt = with pkgs.vimPlugins; [
        # dependencies
        plenary-nvim
        nui-nvim

        catppuccin-nvim
        tokyonight-nvim
        lualine-nvim
        nvim-web-devicons
        nvim-lspconfig
        cord-nvim
        which-key-nvim
        lazydev-nvim
        blink-cmp
        bufferline-nvim
        snacks-nvim
        nvim-autopairs
        nvim-treesitter.withAllGrammars
        nvim-treesitter-textobjects
        mason-nvim
      ];

      dev.myconfig = {
        pure = ../dots/nvim;
        impure = mkOutOfStoreSymlink ../dots/nvim;
      };
    };
  };
}
