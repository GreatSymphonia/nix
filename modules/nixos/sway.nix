{ pkgs, ... }:

{
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-wlr ];

  # Requis pour que swaylock puisse authentifier via PAM.
  security.pam.services.swaylock = { };

  # Requis par udiskie (home/sway.nix) pour le montage automatique des
  # périphériques amovibles — équivalent du "device notifier" de Plasma.
  services.udisks2.enable = true;
}
