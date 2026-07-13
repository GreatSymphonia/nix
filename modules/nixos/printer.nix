{ config, lib, pkgs, ... }:

let
  # Adapte ce nom d'utilisateur pour lui donner l'accès direct au périphérique.
  user = "louis";
in
{
  # --- Règle udev : accès non-root au périphérique USB de la QL-570 ---
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04f9", ATTRS{idProduct}=="202a", MODE="0664", GROUP="lp", SYMLINK+="usb/brother_ql570"
    KERNEL=="lp[0-9]*", ATTRS{idVendor}=="04f9", ATTRS{idProduct}=="202a", MODE="0664", GROUP="lp"
  '';

  # --- Appartenance au groupe lp pour l'accès au device ---
  users.users.${user}.extraGroups = [ "lp" ];

  # --- Paquets nécessaires : CLI brother_ql + libusb pour le backend pyusb ---
  environment.systemPackages = with pkgs; [
    (python3.withPackages (ps: [ ps.brother-ql ]))
    libusb1
  ];

  # Optionnel : si le backend pyusb ne détecte pas le device parce que le
  # module usblp l'a déjà capturé, on peut le blacklister (au prix de perdre
  # /dev/usb/lp0, donc le backend "linux_kernel" ne fonctionnera plus) :
  # boot.blacklistedKernelModules = [ "usblp" ];
}
