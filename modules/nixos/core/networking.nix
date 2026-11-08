{ pkgs, ... }:

{
  networking.hostName = "nixos";
  networking.networkmanager = {
    enable = true;
    plugins = [ pkgs.networkmanager-openvpn ];
  };
}
