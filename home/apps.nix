{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Terminal
    ghostty

    # Dev GUI
    kdePackages.kate
    dbeaver-bin         # client SQL universel

    # Utilitaires
    kdePackages.filelight  # visualiseur d'espace disque
    kdePackages.kcalc
    kdePackages.yakuake

    ansible-lint
    fastfetch
    discord
    onlyoffice-desktopeditors
    slack
    teams-for-linux
    kicad
    kubectl
    # krew
    kubelogin-oidc
    talosctl
    nil
  ];

  programs.ghostty = {
    enable = true;

    settings = {
      background             = "1e1e2e";
      background-opacity     = 0.8;
      background-blur-radius = 20;
      foreground             = "cdd6f4";
      cursor-color           = "f5e0dc";
      selection-background   = "585b70";
      selection-foreground   = "cdd6f4";

      palette = [
        "0=#45475a"  "1=#f38ba8"  "2=#a6e3a1"  "3=#f9e2af"
        "4=#89b4fa"  "5=#f5c2e7"  "6=#94e2d5"  "7=#bac2de"
        "8=#585b70"  "9=#f38ba8"  "10=#a6e3a1" "11=#f9e2af"
        "12=#89b4fa" "13=#f5c2e7" "14=#94e2d5" "15=#a6adc8"
      ];

      font-family       = "FiraCode Nerd Font";
      font-size         = 13;
      window-decoration = true;
      cursor-style      = "block";
      shell-integration = "bash";

      # extraConfig = ''
      #   keybind = super+alt+t=toggle_quick_terminal
      #   quick-terminal-position = top
      #   quick-terminal-size = 30%
      # '';
    };
  };
}
