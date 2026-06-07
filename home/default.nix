{ pkgs, ... }: {
  imports = [
    ./shell.nix
    ./git.nix
    ./editors.nix
    ./apps.nix
    ./theme.nix
    ./plasma.nix
    ./networkmanager.nix
    ./claude-code.nix
  ];

  home.packages = with pkgs; [
    home-manager
    atool
    httpie
    ripgrep
    fd
    bat
    eza
    fzf
    jq
    yq
    tmux
    htop
    btop
    micro

    # Dev CLI
    gnumake
    gcc
    python3
    nodejs
  ];

  home.sessionVariables = {
    BROWSER = "firefox";
    EDITOR  = "micro";
    VISUAL  = "micro";
    GTK_IM_MODULE = "simple";
  };

  home.file.".config/micro/settings.json".text = ''
    {
      "colorscheme": "default",
      "tabsize": 2,
      "tabstospaces": true,
      "autoclose": true,
      "autoindent": true,
      "mouse": true,
      "ruler": true,
      "savecursor": true,
      "saveundo": true
    }
  '';

  home.file.".config/micro/colorschemes/catppuccin-mocha-transparent.micro".text = ''
    color-link default "#cdd6f4,none"
    color-link comment "#6c7086,none"
    color-link identifier "#cba6f7,none"
    color-link constant "#fab387,none"
    color-link constant.number "#fab387,none"
    color-link constant.string "#a6e3a1,none"
    color-link statement "#89b4fa,none"
    color-link symbol.operator "#89dceb,none"
    color-link preproc "#f38ba8,none"
    color-link type "#f9e2af,none"
    color-link special "#f5c2e7,none"
    color-link underline "#89b4fa,none"
    color-link underline.url "#89b4fa,none"
    color-link statusline "#1e1e2e,#cba6f7"
    color-link statusline.inactive "#6c7086,#313244"
    color-link tabbar "#1e1e2e,#313244"
    color-link indent-char "#313244,none"
    color-link line-number "#6c7086,none"
    color-link current-line-number "#cdd6f4,none"
    color-link cursor-line "#313244,none"
    color-link color-column "#313244,none"
    color-link gutter-error "#f38ba8,none"
    color-link gutter-warning "#f9e2af,none"
    color-link diff-added "#a6e3a1,none"
    color-link diff-modified "#f9e2af,none"
    color-link diff-deleted "#f38ba8,none"
    color-link match-brace "#a6e3a1,none"
    color-link error "#f38ba8,none"
    color-link todo "#f9e2af,none"
    color-link selection "#585b70,none"
    color-link search "#f9e2af,#45475a"
    color-link search.lazy "#89b4fa,#313244"
  '';

  home.stateVersion = "25.11";
}
