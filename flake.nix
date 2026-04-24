{
  description = "NixOS system configuration (progressive flake migration)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, nixpkgs-unstable, home-manager, plasma-manager, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    unstablePkgs = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    apps.${system}.home-manager = {
      type = "app";
      program = "${home-manager.packages.${system}.home-manager}/bin/home-manager";
    };

    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit unstablePkgs;
      };
      modules = [
        home-manager.nixosModules.home-manager
        {
          home-manager.sharedModules = [
            plasma-manager.homeModules.plasma-manager
          ];
        }
        ./configuration.nix
      ];
    };

    homeConfigurations."louis@nixos" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        unstable = unstablePkgs;
      };
      modules = [
        ./home
        plasma-manager.homeModules.plasma-manager
        {
          home.username = "louis";
          home.homeDirectory = "/home/louis";
        }
      ];
    };
  };
}
