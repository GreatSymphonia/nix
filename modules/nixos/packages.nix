{ config, pkgs, ... }:

{
  # Paquets systeme (le minimum — le reste va dans home-manager)
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
      obs-vaapi #optional AMD hardware acceleration
      obs-gstreamer
      obs-vkcapture
    ];
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    displaylink
    fprintd
    kdePackages.plasma-thunderbolt
    screen
    wireshark
    ripgrep

    # VPN
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
