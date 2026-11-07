{ inputs, pkgs, ... }:
{
  home.packages = [
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.opencode
  ];
}