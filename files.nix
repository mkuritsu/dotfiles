useSymlinks:
{
  config,
  lib,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  parsePath =
    path:
    builtins.replaceStrings
      [ (builtins.toString ./.) ]
      [ "${builtins.getEnv "FLAKE_ROOT"}/users/kuritsu/dotfiles" ]
      (builtins.toString path);
  sourceFile = path: if useSymlinks then mkOutOfStoreSymlink (parsePath path) else parsePath path;

  stripPath = path: str: builtins.replaceStrings [ (builtins.toString path) ] [ "" ] str;
  substr1 = str: builtins.substring 1 (builtins.stringLength str) str;
  recurseFileStrings = path: map builtins.toString (lib.filesystem.listFilesRecursive path);
  scriptPathToAttrs = path: {
    name = ''${substr1 (stripPath ./dots path)}'';
    value = {
      source = sourceFile path;
    };
  };

  nvimFiles = map scriptPathToAttrs (recurseFileStrings ./dots/nvim);
in
{
  xdg.configFile = {
    "Kvantum/Tokyonight".source = sourceFile ./dots/Kvantum/Tokyonight;
    "Kvantum/kvantum.kvconfig".source = sourceFile ./dots/Kvantum/kvantum.kvconfig;
    "qt6ct/qt6ct.conf".source = sourceFile ./dots/qt6ct/qt6ct.conf;

    "kdeglobals".source = sourceFile ./dots/kdeglobals;

    "mako/config".source = sourceFile ./dots/mako/config;

    "hypr/hyprland.conf".source = sourceFile ./dots/hypr/hyprland.conf;
    "hypr/hypridle.conf".source = sourceFile ./dots/hypr/hypridle.conf;
    "uwsm/env".source = sourceFile ./dots/uwsm/env;

    "fuzzel/fuzzel.ini".source = sourceFile ./dots/fuzzel/fuzzel.ini;

    "imv/config".source = sourceFile ./dots/imv/config;

    "niri/config.kdl".source = sourceFile ./dots/niri/config.kdl;

    "btop/btop.conf".source = sourceFile ./dots/btop/btop.conf;
    "btop/themes".source = sourceFile ./dots/btop/themes;

    "git/config".source = sourceFile ./dots/git/config;

    "tmux/tmux.conf".source = sourceFile ./dots/tmux/tmux.conf;

    "starship.toml".source = sourceFile ./dots/starship.toml;

    "kitty/kitty.conf".source = sourceFile ./dots/kitty/kitty.conf;
    "kitty/themes".source = sourceFile ./dots/kitty/themes;
    "ghostty/config".source = sourceFile ./dots/ghostty/config;

    "fish/config.fish".source = sourceFile ./dots/fish/config.fish;
    "fish/functions/cd_fzf.fish".source = sourceFile ./dots/fish/functions/cd_fzf.fish;
    "fish/functions/fish_user_key_bindings.fish".source =
      ./dots/fish/functions/fish_user_key_bindings.fish;
    "fish/functions/fish_greeting.fish".source = sourceFile ./dots/fish/functions/fish_greeting.fish;

    "xdg-desktop-portal/Hyprland-portals.conf".source = ./dots/xdg-desktop-portal/Hyprland-portals.conf;
  }
  // builtins.listToAttrs nvimFiles;
}
