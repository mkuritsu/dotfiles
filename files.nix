{ config, ... }:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
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

    "nvim".source = mkOutOfStoreSymlink ./dots/nvim;
  };

}
