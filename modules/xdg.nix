{ ... }:
{
  xdg = {
    userDirs = {
      enable = true;
      createDirectories = true;
    };
    terminal-exec = {
      enable = true;
      settings = {
        GNOME = [ "ghostty.desktop" ];
        default = [ "ghostty.desktop" ];
      };
    };
  };
}
