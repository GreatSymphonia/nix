{ config, pkgs, ... }:

{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot = {
    kernelPackages = pkgs.linuxPackages_6_6;
    extraModulePackages = [ config.boot.kernelPackages.evdi ];
    initrd = {
      # Modules that are always loaded by the initrd.
      kernelModules = [
        "evdi"
      ];
    };
  };
}