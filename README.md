# Kuritsu's dotfiles

## Dependencies

### Required
- hyprland (tiling wayland compositor, also use the xdg-desktop-portal)
- hyprpaper (wallpaper utility for hyprland)
- hypridle (idle daemon)
- hyprlock (screen lock)
- hyprpicker (color picker)
- waybar (bar)
- wofi (program launcher)
- dunst (notification daemon)
- slurp (region selector)
- grim (screen copy)
- wf-recorder (wayland screen recorder)
- foot (terminal)
- uwsm (wayland session manager)
- wl-clipboard (clipboard manager)

### Optional
- btop (system mnitor)
- nautilus (file manager)

Note: the dotfiles are configured to use nautilus as the file-manager but that can be changed easily in the config file

## Installation

- Ensure all dependencies are installed and respective services running

### Arch

The recommended way to install is to create a symlink for each file in the respective directory.

### NixOS

If you are using NixOS you can simply import the `dotfiles.nix` file as module in home-manager and it will take care of symlink the config files.

Note: it will not symlink the zsh file because the paths for the plugins need to be in the /nix/store and managed by NixOS, for the zsh can manage it with home-manager attributes (here is my config: https://github.com/mkuritsu/nixconfig)