{ pkgs, standalone ? false, ... }: {
  home.stateVersion = "24.11";

  home.username = "kuritsu";
  home.homeDirectory = "/home/kuritsu";

  dconf.settings = {
    "org/gnome/desktop/interface" = { color-scheme = "prefer-dark"; };
  };

  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
  };

  programs = {
    home-manager.enable = true;
    zsh = pkgs.lib.mkIf (!standalone) {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history.share = false;
      oh-my-zsh = {
        enable = true;
        plugins = [ "git" ];
        theme = "robbyrussell";
      };
    };

    direnv = pkgs.lib.mkIf (!standalone) {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
  };

  # symlink files
  home.file.".config/btop/btop.conf".source = ./.config/btop/btop.conf;
  home.file.".config/btop/themes/catppuccin_mocha.theme".source =
    ./.config/btop/themes/catppuccin_mocha.theme;

  home.file.".config/dunst/dunstrc".source = ./.config/dunst/dunstrc;

  home.file.".config/foot/foot.ini".source = ./.config/foot/foot.ini;

  home.file.".config/hypr/hyprland.conf".source = ./.config/hypr/hyprland.conf;
  home.file.".config/hypr/hyprpaper.conf".source =
    ./.config/hypr/hyprpaper.conf;

  home.file.".config/waybar/config.jsonc".source =
    ./.config/waybar/config.jsonc;
  home.file.".config/waybar/style.css".source = ./.config/waybar/style.css;
  home.file.".config/waybar/modules/notifications_bell.sh".source =
    ./.config/waybar/modules/notifications_bell.sh;

  home.file.".config/wofi/config".source = ./.config/wofi/config;
  home.file.".config/wofi/style.css".source = ./.config/wofi/style.css;
}
