{ pkgs, ... }:
{
  programs.opencode = {
    enable = true;
    package = pkgs.unstable.opencode;

    # Évite les mises à jour hors de Nix.
    settings.autoupdate = false;
    tui.theme = "system";

    extraPackages = with pkgs; [
      git
      ripgrep
      fd
    ];
  };

  home.packages = [
    pkgs.unstable.opencode-desktop
  ];

  xdg.mimeApps.defaultApplications."x-scheme-handler/opencode" = "ai.opencode.desktop.desktop";
}
