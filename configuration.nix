{ config, pkgs, ... }:
let
  home-manager = builtins.fetchTarball https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz;
in {
  imports = [
    ./hardware-configuration.nix
    (import "${home-manager}/nixos")
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Réseau
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Fuseau horaire et locale
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "fr_CA.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "fr_CA.UTF-8";
    LC_IDENTIFICATION = "fr_CA.UTF-8";
    LC_MEASUREMENT    = "fr_CA.UTF-8";
    LC_MONETARY       = "fr_CA.UTF-8";
    LC_NAME           = "fr_CA.UTF-8";
    LC_NUMERIC        = "fr_CA.UTF-8";
    LC_PAPER          = "fr_CA.UTF-8";
    LC_TELEPHONE      = "fr_CA.UTF-8";
    LC_TIME           = "fr_CA.UTF-8";
  };

  # Bureau KDE Plasma 6
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Clavier
  services.xserver.xkb = { layout = "ca"; variant = "multix"; };
  console.keyMap = "cf";

  # Impression
  services.printing.enable = true;

  # Audio (PipeWire)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = { Experimental = true; FastConnectable = true; };
      Policy   = { AutoEnable = true; };
    };
  };

  # Utilisateur
  users.users.louis = {
    isNormalUser = true;
    description  = "Louis Raymond";
    extraGroups  = [ "networkmanager" "wheel" ];
  };

  # Home Manager
  home-manager.users.louis = import ./home;
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  # Paquets système (le minimum — le reste va dans home-manager)
  programs.firefox.enable = true;
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
  ];

  system.stateVersion = "25.11";
}
