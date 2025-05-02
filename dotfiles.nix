# If using nix, this should be included as a home-manger module in the imports
{ home, ... }:
{
  home.file.".config/btop/btop.conf".source = ./.config/btop/btop.conf;
  home.file.".config/btop/themes/catppuccin_mocha.theme".source =
    ./.config/btop/themes/catppuccin_mocha.theme;

  home.file.".config/dunst/dunstrc".source = ./.config/dunst/dunstrc;

  home.file.".config/foot/foot.ini".source = ./.config/foot/foot.ini;

  home.file.".config/hypr/hyprland.conf".source = ./.config/hypr/hyprland.conf;
  home.file.".config/hypr/hyprpaper.conf".source = ./.config/hypr/hyprpaper.conf;

  home.file.".config/waybar/config.json".source = ./.config/waybar/config.json;
  home.file.".config/waybar/style.css".source = ./.config/waybar/style.css;
  home.file.".config/waybar/modules/notifications_bell.sh".source =
    ./.config/waybar/modules/notifications_bell.sh;

  home.file.".config/wofi/config".source = ./.config/wofi/config;
  home.file.".config/wofi/style.css".source = ./.config/wofi/style.css;
}
