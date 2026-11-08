{ ... }:

{
  catppuccin.swaync = {
    enable = true;
    font = "FiraCode Nerd Font";
    fontSize = "12";
  };

  # Notifications : swaync remplace mako pour avoir un vrai panneau
  # d'historique (équivalent du centre de notifications Plasma), pas
  # seulement des popups éphémères. Le style vient de catppuccin.swaync.
  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";
      timeout = 6;
      timeout-low = 4;
      timeout-critical = 0;
      notification-window-width = 400;
      control-center-width = 400;
    };
  };
}
