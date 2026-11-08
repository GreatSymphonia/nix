{ pkgs, ... }:

{
  programs.swaylock = {
    enable = true;
    settings = {
      color = "1e1e2e";
      inside-color = "1e1e2e";
      ring-color = "89b4fa";
      text-color = "cdd6f4";
      ignore-empty-password = true;
    };
  };

  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 300;
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }
      {
        timeout = 600;
        command = "swaymsg 'output * dpms off'";
        resumeCommand = "swaymsg 'output * dpms on'";
      }
    ];
    events = {
      before-sleep = "${pkgs.swaylock}/bin/swaylock -f";
    };
  };
}
