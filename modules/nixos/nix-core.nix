{ pkgs, ... }:

{
  system.stateVersion = "26.05";

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Lets generic dynamically-linked Linux binaries run on NixOS, e.g. the
  # claude-code CLI that claude-desktop downloads on its own into
  # ~/.config/Claude/claude-code/<version>/claude (outside of our nix
  # derivation, so autoPatchelfHook never touches it).
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    openssl
    icu
    curl
  ];
}