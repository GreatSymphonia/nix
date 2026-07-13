{ unstablePkgs, ... }:

let
  unstable = unstablePkgs;
in {
  imports = [
    ./modules/printer/brotherql570.nix

    ./hardware-configuration.nix
    ./modules/nixos/audio.nix
    ./modules/nixos/bluetooth.nix
    ./modules/nixos/boot.nix
    ./modules/nixos/desktop.nix
    ./modules/nixos/nix-core.nix
    ./modules/nixos/packages.nix
    ./modules/nixos/system-locale.nix
    # ./modules/nixos/printer.nix
    ./modules/nixos/user.nix
    ./modules/nixos/virtualisation.nix
  ];

  # Home Manager
  home-manager.users.louis = { ... }: {
    imports = [
      ./home
    ];
  };
  home-manager.backupFileExtension = "bak";
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit unstable; };
}
