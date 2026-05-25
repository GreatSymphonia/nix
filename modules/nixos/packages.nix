{ config, pkgs, ... }:
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

  environment.systemPackages = with pkgs; [
    vim
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

    (python3.withPackages (python-pkgs: with python-pkgs; [
      pandas
      requests
      ansible
      ansible-core
      ansible-lint
    ]))
  ];
}