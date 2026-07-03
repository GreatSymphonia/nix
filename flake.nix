{
  description = "NixOS system configuration (progressive flake migration)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };

  outputs = inputs@{ nixpkgs, nixpkgs-unstable, home-manager, plasma-manager, catppuccin, nix-flatpak, ... }:
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
        inherit unstablePkgs inputs;
      };
      modules = [
        home-manager.nixosModules.home-manager
        {
          home-manager.extraSpecialArgs = { unstable = unstablePkgs; };
          home-manager.sharedModules = [
            plasma-manager.homeModules.plasma-manager
            catppuccin.homeModules.catppuccin
            nix-flatpak.homeManagerModules.nix-flatpak
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
        catppuccin.homeModules.catppuccin
        {
          home.username = "louis";
          home.homeDirectory = "/home/louis";
        }
      ];
    };
  };
}
