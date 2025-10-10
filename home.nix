{ pkgs, ... }:
{
  imports = [
    ./files.nix
    ./modules/gtk.nix
    ./modules/xdg.nix
  ];

  home.packages = with pkgs; [
    app2unit # here because not commonly packaged in other distros
  ];
}
