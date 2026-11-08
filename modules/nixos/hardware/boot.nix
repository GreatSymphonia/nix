{
  config,
  lib,
  pkgs,
  ...
}:

{
  # lanzaboote remplace le stub systemd-boot par une version signée pour le
  # Secure Boot avec nos clés (PK/KEK/db). Les clés vivent hors dépôt dans
  # /etc/secureboot (voir docs/secure-boot.md).
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };

  # Pointe la CLI sbctl vers le même pkiBundle que lanzaboote, sinon elle
  # retombe sur son défaut /var/lib/sbctl.
  environment.systemPackages = [ pkgs.sbctl ];
  environment.etc."sbctl/sbctl.conf".text = ''
    keydir: ${config.boot.lanzaboote.pkiBundle}/keys
    guid: ${config.boot.lanzaboote.pkiBundle}/GUID
  '';

  boot.extraModulePackages = [ config.boot.kernelPackages.evdi ];
  boot.initrd.kernelModules = [ "evdi" ];
}
