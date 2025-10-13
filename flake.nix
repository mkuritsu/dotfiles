{
  description = "mkuritu's dotfiles";

  outputs =
    { ... }:
    {
      homeModules.default = ./home.nix;
    };
}
