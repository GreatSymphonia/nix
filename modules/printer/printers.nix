# modules/brother-ql570.nix

{ pkgs, ... }:

let
  brotherQl570 =
    pkgs.callPackage
      ./brotherql570.nix
      {};
in
{
  services.printing = {
    enable = true;

    drivers = [
      brotherQl570
    ];
  };
}