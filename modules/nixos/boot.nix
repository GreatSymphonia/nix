{ config, lib, pkgs, ... }:

{
  # Bootloader
  # lanzaboote remplace le stub systemd-boot par une version signée pour le
  # Secure Boot avec nos propres clés (PK/KEK/db) ; les clés vivent hors-repo
  # dans /etc/secureboot (générées et enrôlées via sbctl, voir doc secure-boot).
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };
  environment.systemPackages = [ pkgs.sbctl ];
  # Pointe la CLI sbctl (invoquée manuellement, hors lanzaboote) vers le même
  # pkiBundle que lanzaboote, sinon elle retombe sur son défaut /var/lib/sbctl.
  environment.etc."sbctl/sbctl.conf".text = ''
    keydir: ${config.boot.lanzaboote.pkiBundle}/keys
    guid: ${config.boot.lanzaboote.pkiBundle}/GUID
  '';
  boot = {
    extraModulePackages = [ config.boot.kernelPackages.evdi ];
    initrd = {
      # Modules that are always loaded by the initrd.
      kernelModules = [
        "evdi"
      ];
    };
  };
}