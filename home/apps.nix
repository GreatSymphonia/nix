{ pkgs, unstable, inputs, ... }: {
  home.packages = with pkgs; [
    # Terminal
    ghostty

    (pkgs.callPackage ./claude-desktop.nix { })

    # Dev GUI
    kdePackages.kate
    dbeaver-bin         # client SQL universel

    # Utilitaires
    kdePackages.filelight  # visualiseur d'espace disque
    kdePackages.kcalc
    kdePackages.yakuake
    kdePackages.partitionmanager

    satisfactorymodmanager
    zed
    ansible-lint
    fastfetch
    slack
    onlyoffice-desktopeditors
    teams-for-linux
    kicad
    kubectl
    kubernetes-helm
    filezilla
    prismlauncher
    google-cloud-sdk
    nextcloud-client
    # pandoc utilise pdflatex par défaut, qui ne gère pas les caractères
    # Unicode (ex: ≈). On force xelatex, qui les gère nativement.
    (pkgs.symlinkJoin {
      name = "pandoc-xelatex";
      paths = [ pandoc ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/pandoc --add-flags "--pdf-engine=xelatex"
      '';
    })
    texlive.combined.scheme-full
    zotero
    parted
    grub2_efi
    dosfstools


    (wrapHelm kubernetes-helm {
      plugins = with pkgs.kubernetes-helmPlugins; [
        helm-secrets
        helm-diff
        helm-s3
        helm-git
      ];
    })

    sonar-scanner-cli

    forgejo-cli

    # krew
    kubelogin-oidc
    talosctl
    unstable.omnictl
    nil

    # Dusklight — port PC natif de Twilight Princess. Le build depuis le
    # flake amont (github:TwilitRealm/dusklight) échoue actuellement :
    # sur la branche main, le submodule extern/aurora attend une version
    # de dawn plus récente que celle que le flake épingle (static_assert
    # "capturing lambdas aren't supported for repeatable callbacks" dans
    # dawn/webgpu_cpp.h) — bug amont indépendant de notre packaging.
    # On installe donc l'AppImage officielle à la place :
    # https://github.com/TwilitRealm/dusklight/releases
    (let
      version = "1.4.1";
      appimage = pkgs.fetchurl {
        url = "https://github.com/TwilitRealm/dusklight/releases/download/v${version}/Dusklight-v${version}-linux-x86_64.AppImage";
        hash = "sha256-9d0TCMExQwlFzBLN1E8i0x491uxUWEmEkZJKXp+pLUA=";
      };
      appimageContents = pkgs.appimageTools.extractType2 {
        pname = "dusklight";
        inherit version;
        src = appimage;
      };
    in
    pkgs.appimageTools.wrapType2 {
      pname = "dusklight";
      inherit version;
      src = appimage;
      extraInstallCommands = ''
        install -Dm444 ${appimageContents}/dev.twilitrealm.dusk.desktop \
          $out/share/applications/dev.twilitrealm.dusk.desktop
        install -Dm444 ${appimageContents}/dev.twilitrealm.dusk.png \
          $out/share/icons/hicolor/512x512/apps/dev.twilitrealm.dusk.png
      '';
    })
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
    };
  };
}
