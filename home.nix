{ lib, pkgs, ... }:
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
in
{
  home = {
    stateVersion = "25.05";
    inherit username homeDirectory;
  };

  imports = [
    ./files.nix
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

  programs.home-manager.enable = true;
}
