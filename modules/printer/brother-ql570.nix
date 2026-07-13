{ pkgs, ... }:

let
  brotherQl570 =
    pkgs.callPackage
      ../pkgs/brother-ql570
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