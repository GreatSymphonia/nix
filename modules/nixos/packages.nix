{ config, inputs, pkgs, services, ... }:
{
  programs.firefox.enable = true;
  programs.steam.enable = true;
  programs.wireshark = {
    enable = true;
    dumpcap.enable = true;
    usbmon.enable = true;
    package = pkgs.wireshark;
  };
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
      obs-vaapi
      obs-gstreamer
      obs-vkcapture
    ];
  };

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    substituters = [ "https://cache.nixos.org" ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  environment.systemPackages = with pkgs; [
    vim
    nmap
    traceroute
    wget
    curl
    git
    fprintd
    kdePackages.plasma-thunderbolt
    screen
    ripgrep
    clonehero
    yarg
    wireguard-tools
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    krita
    gimp
    inkscape
    temurin-bin-8
    temurin-bin-11
    temurin-bin-21

    (python3.withPackages (python-pkgs: with python-pkgs; [
      pandas
      requests
      ansible
      ansible-core
      ansible-lint
    ]))
  ];
}