{ pkgs, ... }: {
  programs.bash = {
    enable = true;

    historySize     = 10000;
    historyFileSize = 20000;
    historyControl  = [ "ignoredups" "ignorespace" "erasedups" ];

    shellAliases = {
      ".."   = "cd ..";
      "..."  = "cd ../..";
      ll     = "eza -la --icons --group-directories-first";
      ls     = "eza --icons --group-directories-first";
      tree   = "eza --tree --icons";
      df     = "df -h";
      du     = "du -sh";
      nixupdate  = "sudo nix flake update --flake /etc/nixos && sudo nixos-rebuild switch --flake /etc/nixos#nixos && nixsecureboot-check";
      nixcleanup = "sudo nix-collect-garbage -d";
      nixrebuild = "sudo nixos-rebuild switch --flake /etc/nixos#nixos && nixsecureboot-check";
      nixboot = "sudo nixos-rebuild boot --flake /etc/nixos#nixos && nixsecureboot-check";
      nixtest = "sudo nixos-rebuild test --flake /etc/nixos#nixos";
      nixcheck = "sudo nixos-rebuild build --flake /etc/nixos#nixos --show-trace";
      nixgit = "sudo sh -c 'cd /etc/nixos && git add -A && git commit -m ''wip'''";
      nixpush = "sudo sh -c 'cd /etc/nixos && git push'";
      hmcheck = "nix run path:/etc/nixos#home-manager -- build --flake path:/etc/nixos#louis@nixos --no-out-link";
      hmrebuild = "nix run path:/etc/nixos#home-manager -- switch -b bak --flake path:/etc/nixos#louis@nixos";
      codenix = "sudo code /etc/nixos --no-sandbox --user-data-dir=/home/louis/vscode-sudo";
    };

    initExtra = ''
      eval "$(fzf --bash)"
      export PATH="$HOME/.local/bin:$PATH"

      # Keep command overrides in interactive shells only.
      if [[ $- == *i* ]]; then
        alias grep='grep --color=auto'
        alias cat='bat --paging=never'
        alias ccat='/run/current-system/sw/bin/cat'
      fi

      # SonarQube — charge le token depuis un fichier local hors-git (chmod 600).
      # Créer le fichier avec: install -Dm600 /dev/stdin ~/.config/sonar-scanner/token <<< "TON_TOKEN"
      if [ -r "$HOME/.config/sonar-scanner/token" ]; then
        export SONAR_TOKEN="$(<"$HOME/.config/sonar-scanner/token")"
      fi

      # Vérifie après chaque rebuild que les fichiers de boot NixOS sont bien
      # signés (lanzaboote les signe automatiquement à l'activation) et que
      # la chaîne Secure Boot de Windows (bootmgfw.efi, signé Microsoft) est
      # toujours reconnue par le db enrôlé avec `sbctl enroll-keys --microsoft`.
      nixsecureboot-check() {
        if ! command -v sbctl >/dev/null 2>&1; then
          echo "sbctl n'est pas installé, secure-boot pas encore configuré (voir doc secure-boot)." >&2
          return 0
        fi
        echo "== Vérification Secure Boot (NixOS + Windows) sur /boot =="
        sudo sbctl verify
      }

      # Compare la version d'omnictl pinnée dans home/apps.nix à celle exigée
      # par notre instance Omni (cedille), qui sert justement le binaire
      # attendu par le serveur à cette URL. N'écrit rien — affiche juste le
      # nouveau hash à coller dans apps.nix si une mise à jour est dispo.
      omnictl-check-update() {
        local omni_url="https://cedille.na-west-1.omni.siderolabs.io/api/omnictl/omnictl-linux-amd64"
        local apps_nix="/etc/nixos/home/apps.nix"
        local pinned
        pinned="$(grep -B5 'pname = "omnictl"' "$apps_nix" | grep -oP 'version = "\K[0-9.]+' | head -1)"

        if [ -z "$pinned" ]; then
          echo "Impossible de trouver la version pinnée d'omnictl dans $apps_nix" >&2
          return 1
        fi

        local tmp
        tmp="$(mktemp)"
        trap 'rm -f "$tmp"' RETURN

        echo "Téléchargement du binaire servi par l'instance Omni..."
        if ! curl -sSfL -o "$tmp" "$omni_url"; then
          echo "Échec du téléchargement depuis $omni_url" >&2
          return 1
        fi
        chmod +x "$tmp"

        local server_version
        server_version="$("$tmp" --version 2>/dev/null | grep -oP '(?<=version v)[0-9.]+')"
        if [ -z "$server_version" ]; then
          echo "Impossible de déterminer la version servie par l'instance Omni" >&2
          return 1
        fi

        echo "Version pinnée (apps.nix) : $pinned"
        echo "Version servie (Omni)     : $server_version"

        if [ "$pinned" = "$server_version" ]; then
          echo "omnictl est à jour."
          return 0
        fi

        local hash
        hash="$(nix hash file "$tmp" 2>/dev/null)"

        echo
        echo "Mise à jour disponible ! Dans $apps_nix, remplace :"
        echo "  version = \"$pinned\";"
        echo "par :"
        echo "  version = \"$server_version\";"
        echo "et le hash par :"
        echo "  hash = \"$hash\";"
      }

      enixcfg() {
        local arg="$1"
        local subcmd="$1"

        case "$arg" in
          mod/*)                    subcmd="$arg" ;;
          module/*|modules/*)       subcmd="mod/''${arg#*/}" ;;
          mod|module|modules)       subcmd="" ;;
        esac

        case "$subcmd" in
          ""|main)      sudo -E micro /etc/nixos/configuration.nix ;;
          home)         sudo -E micro /etc/nixos/home/default.nix ;;
          shell)        sudo -E micro /etc/nixos/home/shell.nix ;;
          flake)        sudo -E micro /etc/nixos/flake.nix ;;
          lock)         sudo -E micro /etc/nixos/flake.lock ;;
          git)          sudo -E micro /etc/nixos/home/git.nix ;;
          editors)      sudo -E micro /etc/nixos/home/editors.nix ;;
          apps)         sudo -E micro /etc/nixos/home/apps.nix ;;
          theme)        sudo -E micro /etc/nixos/home/theme.nix ;;
          mod/boot)     sudo -E micro /etc/nixos/modules/nixos/boot.nix ;;
          mod/locale)   sudo -E micro /etc/nixos/modules/nixos/system-locale.nix ;;
          mod/desktop)  sudo -E micro /etc/nixos/modules/nixos/desktop.nix ;;
          mod/audio)    sudo -E micro /etc/nixos/modules/nixos/audio.nix ;;
          mod/bt)       sudo -E micro /etc/nixos/modules/nixos/bluetooth.nix ;;
          mod/user)     sudo -E micro /etc/nixos/modules/nixos/user.nix ;;
          mod/packages) sudo -E micro /etc/nixos/modules/nixos/packages.nix ;;
          mod/nix)      sudo -E micro /etc/nixos/modules/nixos/nix-core.nix ;;
          mod/virt)     sudo -E micro /etc/nixos/modules/nixos/virtualisation.nix ;;
          *)            echo -E "Sous-commandes: main home shell flake lock git editors apps theme | Modules: mod/<boot|locale|desktop|audio|bt|user|packages|nix|virt>" ;;
        esac
      }

      _enixcfg_complete() {
        local cur="''${COMP_WORDS[COMP_CWORD]}"
        local core_cmds="main home shell flake lock git editors apps theme mod/"
        local mod_cmds="mod/boot mod/locale mod/desktop mod/audio mod/bt mod/user mod/packages mod/nix mod/virt"

        if [[ "''${cur}" == mod/* ]]; then
          COMPREPLY=($(compgen -W "$mod_cmds" -- "''${cur}"))
        else
          COMPREPLY=($(compgen -W "$core_cmds $mod_cmds" -- "''${cur}"))
        fi
      }
      complete -F _enixcfg_complete enixcfg
    '';
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.starship = {
    enable = true;
    settings = {
      format = "$directory$git_branch$git_status$nix_shell$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol   = "[❯](bold red)";
      };
      directory = {
        style             = "bold blue";
        truncation_length = 4;
      };
      git_branch.style  = "bold purple";
      git_status.style  = "bold red";
      nix_shell = {
        symbol = "❄️ ";
        style  = "bold cyan";
      };
    };
  };
}
