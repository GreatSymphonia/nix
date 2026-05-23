{ config, ... }:

{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot = {
    # extraModulePackages = [ config.boot.kernelPackages.evdi ];
    initrd = {
      # Modules that are always loaded by the initrd.
      kernelModules = [
        # "evdi"
      ];
    };
  };
}