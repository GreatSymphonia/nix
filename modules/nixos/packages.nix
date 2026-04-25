{ pkgs, ... }:

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

    (python3.withPackages (python-pkgs: with python-pkgs; [
      pandas
      requests
      ansible
      ansible-core
      ansible-lint
    ]))
  ];
}
