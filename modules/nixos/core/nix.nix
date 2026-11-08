{ pkgs, ... }:

{
  system.stateVersion = "26.05";

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Permet d'exécuter des binaires Linux dynamiques non packagés.
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib # Fournit libstdc++.so.6, crucial pour de nombreux binaires
    zlib
    openssl
    icu
    curl
    sqlite
    xz
  ];
}
