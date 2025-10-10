{
  description = "mkuritu's dotfiles";

  outputs =
    { ... }:
    {
      homeManagerModules = {
        default = ./home.nix;
        full = ./home-nixos.nix;
      };
    };
}
