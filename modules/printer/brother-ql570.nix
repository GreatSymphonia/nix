{ pkgs, brotherQl570Sources, ... }:

let
  brotherQl570 =
    pkgs.callPackage
      ../pkgs/brother-ql570
      {
        inherit brotherQl570Sources;
      };
in
{
  services.printing = {
    enable = true;

    drivers = [
      brotherQl570
    ];
  };
}