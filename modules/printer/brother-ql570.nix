{ pkgs, ... }:

let
  brotherQl570 =
    pkgs.callPackage
      ../pkgs/brother-ql570
      {};
in
{
  services.printing.drivers = [
    brotherQl570
  ];
}
