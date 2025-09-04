{ config, lib, ... }:
let
  username =
    if (builtins.getEnv "USER") != "" then
      builtins.getEnv "USER"
    else
      builtins.throw "USER variable not set!";

  homeDirectory =
    if (builtins.getEnv "HOME") != "" then
      builtins.getEnv "HOME"
    else
      builtins.throw "HOME variable not set!";

  isNixOS = builtins.getEnv "NIXOS" == "1";

  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  home = {
    stateVersion = "25.05";
    inherit username homeDirectory;
  };

  imports = [
    ./modules/gtk.nix
    ./modules/xdg.nix
  ]
  ++ lib.optionals isNixOS [
    ./modules/browser.nix
    ./modules/neovim.nix
  ];

  xdg.configFile = {
    "Kvantum/Tokyonight".source = mkOutOfStoreSymlink ./dots/Kvantum/Tokyonight;
    "Kvantum/kvantum.kvconfig".source = mkOutOfStoreSymlink ./dots/Kvantum/kvantum.kvconfig;
    "qt6ct/qt6ct.conf".source = mkOutOfStoreSymlink ./dots/qt6ct/qt6ct.conf;

    "kdeglobals".source = mkOutOfStoreSymlink ./dots/kdeglobals;

    "mako/config".source = mkOutOfStoreSymlink ./dots/mako/config;

    "hypr/hyprland.conf".source = mkOutOfStoreSymlink ./dots/hypr/hyprland.conf;
    "hypr/hypridle.conf".source = mkOutOfStoreSymlink ./dots/hypr/hypridle.conf;
    "uwsm/env".source = mkOutOfStoreSymlink ./dots/uwsm/env;

    "fuzzel/fuzzel.ini".source = mkOutOfStoreSymlink ./dots/fuzzel/fuzzel.ini;

    "imv/config".source = mkOutOfStoreSymlink ./dots/imv/config;

    "niri/config.kdl".source = mkOutOfStoreSymlink ./dots/niri/config.kdl;

    "btop/btop.conf".source = mkOutOfStoreSymlink ./dots/btop/btop.conf;
    "btop/themes".source = mkOutOfStoreSymlink ./dots/btop/themes;

    "git/config".source = mkOutOfStoreSymlink ./dots/git/config;

    "tmux/tmux.conf".source = mkOutOfStoreSymlink ./dots/tmux/tmux.conf;

    "starship.toml".source = mkOutOfStoreSymlink ./dots/starship.toml;

    "kitty/kitty.conf".source = mkOutOfStoreSymlink ./dots/kitty/kitty.conf;
    "kitty/themes".source = mkOutOfStoreSymlink ./dots/kitty/themes;

    "fish/config.fish".source = mkOutOfStoreSymlink ./dots/fish/config.fish;
    "fish/functions/cd_fzf.fish".source = mkOutOfStoreSymlink ./dots/fish/functions/cd_fzf.fish;
    "fish/functions/fish_user_key_bindings.fish".source =
      ./dots/fish/functions/fish_user_key_bindings.fish;
    "fish/functions/fish_greeting.fish".source =
      mkOutOfStoreSymlink ./dots/fish/functions/fish_greeting.fish;

    "user-dirs.dirs".source = mkOutOfStoreSymlink ./dots/user-dirs.dirs;
    "xdg-terminals.list".source = mkOutOfStoreSymlink ./dots/xdg-terminals.list;

    "nvim".source = mkOutOfStoreSymlink ./dots/nvim;
  };
}
