{ pkgs, ... }:

{
  services.xserver.enable = true;
  services.xserver.videoDrivers = [
    "displaylink"
    "modesetting"
  ];
  environment.variables = {
    KWIN_DRM_PREFER_COLOR_DEPTH = "24";
  };

  services.desktopManager.plasma6.enable = true;
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
    };
    defaultSession = "plasma";
  };

  services.fprintd = {
    enable = true;
    tod.enable = true;
    tod.driver = pkgs.libfprint-2-tod1-goodix;
  };
  services.hardware.bolt.enable = true;

  xdg.portal.enable = true;
}
