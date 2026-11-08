{ lib, pkgs, ... }:
{
  programs.java = {
    enable = true;
    package = lib.hiPrio pkgs.temurin-bin-21;
  };

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
  programs.virt-manager.enable = true;

  nixpkgs.config.allowUnfree = true;

  # Permet les paquets non-free pour root (nix shell, nix-env, etc.)
  environment.etc."root/.config/nixpkgs/config.nix".text = ''
    { allowUnfree = true; }
  '';

  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  environment.systemPackages = with pkgs; [
    file
    vim
    nmap
    arp-scan
    mtr
    tcpdump
    netcat
    whois
    iperf3
    openssl
    bandwhich
    sslscan
    gh
    nixd
    vault
    bind
    traceroute
    wget
    curl
    git
    fprintd
    kdePackages.plasma-thunderbolt
    screen
    ripgrep
    unstable.clonehero
    yarg
    wireguard-tools
    zen-browser
    krita
    gimp
    inkscape
    pcsx2
    dolphin-emu
    wineWow64Packages.stable
    winetricks
    temurin-bin-8
    temurin-bin-11
    unzip
    cargo
    luarocks
    go
    vesktop

    (python3.withPackages (
      python-pkgs: with python-pkgs; [
        pandas
        requests
        ansible
        ansible-core
        ansible-lint
        scapy
        pillow
      ]
    ))
  ];
}
