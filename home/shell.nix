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
      cat    = "bat";
      grep   = "grep --color=auto";
      df     = "df -h";
      du     = "du -sh";
      rebuild = "sudo nixos-rebuild switch";
      update  = "sudo nix flake update && sudo nixos-rebuild switch";
      cleanup = "sudo nix-collect-garbage -d";
      g      = "git";
      gs     = "git status";
      gd     = "git diff";
      gl     = "git log --oneline --graph --decorate";
    };

    initExtra = ''
      eval "$(fzf --bash)"
      export PATH="$HOME/.local/bin:$PATH"

      enixcfg() {
        case "$1" in
          ""|main)   sudo micro /etc/nixos/configuration.nix ;;
          home)      sudo micro /etc/nixos/home/default.nix ;;
          shell)     sudo micro /etc/nixos/home/shell.nix ;;
          git)       sudo micro /etc/nixos/home/git.nix ;;
          editors)   sudo micro /etc/nixos/home/editors.nix ;;
          apps)      sudo micro /etc/nixos/home/apps.nix ;;
          theme)     sudo micro /etc/nixos/home/theme.nix ;;
          *)         echo "Sous-commandes: main home shell git editors apps theme" ;;
        esac
      }

      _enixcfg_complete() {
        local cur="''${COMP_WORDS[COMP_CWORD]}"
        COMPREPLY=($(compgen -W "main home shell git editors apps theme" -- "$cur"))
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
