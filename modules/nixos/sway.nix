{ pkgs, ... }:

{
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-wlr ];

  # Requis pour que swaylock puisse authentifier via PAM.
  security.pam.services.swaylock = { };
}
