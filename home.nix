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

  isNixOs = builtins.pathExists "/run/current-system/nixos-version";
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
  ++ lib.optionals isNixOs [
    ./modules/browser.nix
    ./modules/neovim.nix
  ];

  home.packages = with pkgs; [
    app2unit
  ];
}
