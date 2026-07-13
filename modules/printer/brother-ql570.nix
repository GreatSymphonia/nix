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

  # Compatibilité avec les vieux binaires Brother qui utilisent encore
  # des chemins absolus /opt/brother/...
  systemd.tmpfiles.rules = [
    "d /opt 0755 root root - -"
    "L+ /opt/brother - - - - ${brotherQl570}/opt/brother"
  ];
}
