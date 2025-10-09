{ ... }:
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
  imports = [
    (import ./home.nix username homeDirectory isNixOs)
  ];
}
