{ pkgs, ... }:

{
  # Bureau KDE Plasma 6
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "displaylink" "modesetting" ];
  environment.variables = {
    KWIN_DRM_PREFER_COLOR_DEPTH = "24";
    JAVA_HOME = "${pkgs.temurin-bin-21}/lib/openjdk";
  };

  services = {
    desktopManager.plasma6 = {
      enable = true;
    };
    displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
      };
      defaultSession = "plasma";
    };
    fprintd = {
      enable = true;
      tod.enable = true;
      tod.driver = pkgs.libfprint-2-tod1-goodix;
    };
    hardware.bolt.enable = true;
    printing.enable = true;
  };

}