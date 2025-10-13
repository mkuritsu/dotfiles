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
in
{
  home = {
    stateVersion = "25.11";
    inherit username homeDirectory;
  };

  imports = [
    ./home.nix
  ];
}
