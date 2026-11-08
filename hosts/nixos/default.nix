{
  imports = [
    ./hardware-configuration.nix

    ../../modules/nixos/core/locale.nix
    ../../modules/nixos/core/networking.nix
    ../../modules/nixos/core/nix.nix
    ../../modules/nixos/core/users.nix

    ../../modules/nixos/hardware/audio.nix
    ../../modules/nixos/hardware/bluetooth.nix
    ../../modules/nixos/hardware/boot.nix
    ../../modules/nixos/hardware/printer-brother-ql570.nix

    ../../modules/nixos/desktop/plasma.nix
    ../../modules/nixos/desktop/sway.nix
    ../../modules/nixos/desktop/swayfx.nix

    ../../modules/nixos/packages.nix
    ../../modules/nixos/services/android.nix
    ../../modules/nixos/services/flatpak.nix
    ../../modules/nixos/services/virtualisation.nix
  ];

  home-manager.users.louis = {
    imports = [ ../../home ];
  };
}
