{ pkgs, ... }:

{
  services.printing = {
    enable = true;

    drivers = [
      pkgs.brother-ql570
    ];
  };

  # Compatibilité avec les vieux binaires Brother qui utilisent encore
  # des chemins absolus /opt/brother/...
  systemd.tmpfiles.rules = [
    "d /opt 0755 root root - -"
    "L+ /opt/brother - - - - ${pkgs.brother-ql570}/opt/brother"
  ];
}
