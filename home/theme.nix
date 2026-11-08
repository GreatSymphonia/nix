{ pkgs, config, ... }: {
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    candy-icons
    kdePackages.spectacle
    kdePackages.kdeplasma-addons
    nerd-fonts.fira-code
    fira-code
    libsForQt5.qtstyleplugin-kvantum
  ];

  gtk = {
    enable = true;
    # Écrase toujours ~/.gtkrc-2.0 sans créer de .bak : évite que
    # l'activation Home Manager échoue quand un .bak d'un switch précédent
    # est déjà présent.
    gtk2.force = true;
    theme = {
      name = "Catppuccin-Mocha-Standard-Blue-Dark";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "blue" ];
        size = "standard";
        variant = "mocha";
      };
    };
    iconTheme = {
      name = "candy-icons";
      package = pkgs.candy-icons;
    };
    cursorTheme = {
      name = "Catppuccin-Mocha-Dark-Cursors";
      package = pkgs.catppuccin-cursors.mochaDark;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4 = {
      extraConfig.gtk-application-prefer-dark-theme = true;
      theme = config.gtk.theme;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "Breeze";
    style.name = "Breeze";
  };

  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
}
