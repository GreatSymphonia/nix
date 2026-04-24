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
      nixupdate  = "sudo nix flake update --flake /etc/nixos && sudo nixos-rebuild switch --flake /etc/nixos#nixos";
      nixcleanup = "sudo nix-collect-garbage -d";
      nixrebuild = "sudo nixos-rebuild switch --flake /etc/nixos#nixos";
      nixboot = "sudo nixos-rebuild boot --flake /etc/nixos#nixos";
      nixtest = "sudo nixos-rebuild test --flake /etc/nixos#nixos";
      nixcheck = "sudo nixos-rebuild build --flake /etc/nixos#nixos --show-trace";
      hmcheck = "nix run path:/etc/nixos#home-manager -- build --flake path:/etc/nixos#louis@nixos --no-out-link";
      hmrebuild = "nix run path:/etc/nixos#home-manager -- switch --flake path:/etc/nixos#louis@nixos";
      codenix = "sudo code /etc/nixos --no-sandbox --user-data-dir=/home/louis/vscode-sudo";
      g      = "git";
      gs     = "git status";
      gd     = "git diff";
      gl     = "git log --oneline --graph --decorate";
    };

    initExtra = ''
      eval "$(fzf --bash)"
      export PATH="$HOME/.local/bin:$PATH"

      # Keep command overrides in interactive shells only.
      if [[ $- == *i* ]]; then
        alias cat='bat --paging=never'
        alias grep='grep --color=auto'
      fi

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

        if [[ "$cur" == mod/* ]]; then
          COMPREPLY=($(compgen -W "$mod_cmds" -- "$cur"))
        else
          COMPREPLY=($(compgen -W "$core_cmds $mod_cmds" -- "$cur"))
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
