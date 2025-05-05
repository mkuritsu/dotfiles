{
  description = "Kuritsu's dotfiles";

  inputs = rec {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      username = "kuritsu";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      home = ./home.nix;

      homeConfigurations.${username} =
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs;
            standalone = true;
          };
          modules = [
            ({ ... }: {
              home.username = username;
              home.homeDirectory = "/home/${username}";
            })
            ./home.nix
          ];
        };

      devShells.${system}.default = pkgs.mkShell {
        nativeBuildInputs = [ home-manager.packages.${system}.home-manager ];
      };
    };
}
