{
  description = "Kuritsu dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    dotfiles = import ./dotfiles.nix { pkgs = nixpkgs; };
  };
}
