username: homeDirectory: isNixOS:
{
  lib,
  pkgs,
  ...
}:
{
  home = {
    stateVersion = "25.11";
    inherit username homeDirectory;
  };

  imports = [
    (import ./files.nix true)
    ./modules/gtk.nix
    ./modules/xdg.nix
  ]
  ++ lib.optionals isNixOS [
    ./modules/browser.nix
    ./modules/neovim.nix
  ];

  home.packages = with pkgs; [
    app2unit
  ];
}
