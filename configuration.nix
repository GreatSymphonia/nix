{ unstablePkgs, ... }:

let
  unstable = unstablePkgs;
in {
  imports = [
    ./hardware-configuration.nix
    ./modules/nixos/boot.nix
    ./modules/nixos/system-locale.nix
    ./modules/nixos/desktop.nix
    ./modules/nixos/audio.nix
    ./modules/nixos/bluetooth.nix
    ./modules/nixos/user.nix
    ./modules/nixos/packages.nix
    ./modules/nixos/nix-core.nix
    ./modules/nixos/virtualisation.nix
  ];

  # Home Manager
  home-manager.users.louis = { ... }: {
    imports = [
      ./home
    ];
  };
  home-manager.backupFileExtension = "backup";
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit unstable; };
}
