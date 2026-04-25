{ pkgs, ... }:

{
  # Reseau
  networking.hostName = "nixos";
  networking.networkmanager = {
    enable = true;
    plugins = [ pkgs.networkmanager-openvpn ];
  };

  # Fuseau horaire et locale
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "fr_CA.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_CA.UTF-8";
    LC_IDENTIFICATION = "fr_CA.UTF-8";
    LC_MEASUREMENT = "fr_CA.UTF-8";
    LC_MONETARY = "fr_CA.UTF-8";
    LC_NAME = "fr_CA.UTF-8";
    LC_NUMERIC = "fr_CA.UTF-8";
    LC_PAPER = "fr_CA.UTF-8";
    LC_TELEPHONE = "fr_CA.UTF-8";
    LC_TIME = "fr_CA.UTF-8";
  };

  # Clavier
  services.xserver.xkb = { layout = "ca"; variant = "multix"; };
  console.keyMap = "cf";
}