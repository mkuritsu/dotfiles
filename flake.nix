{
  description = "Kuritsu's dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      home = ./home.nix;

      homeConfigurations."kuritsu" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs;
          standalone = true;
        };
        modules = [ ./home.nix ];
      };

      devShells.${system}.default = pkgs.mkShell {
        nativeBuildInputs = [ home-manager.packages.${system}.home-manager ];
      };
    };
}
