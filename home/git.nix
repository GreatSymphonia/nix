{ pkgs, ... }: {
  programs.git = {
    enable = true;
    settings = {
      user.name  = "Louis Raymond";
      user.email = "louis.raymond2017@gmail.com";
      init.defaultBranch = "main";
      pull.rebase        = true;
      push.autoSetupRemote = true;
      push.default         = "current";
      core = {
        editor     = "micro";
        autocrlf   = "input";
      };
      diff.colorMoved = "zebra";
      merge.conflictstyle  = "zdiff3";
      rebase.autoStash     = true;
      alias = {
        st       = "status";
        d        = "diff";
        co       = "checkout";
        br       = "branch";
        lg       = "log --graph --oneline --decorate --all";
        undo     = "reset HEAD~1 --mixed";
        wip      = "!git add -A && git commit -m 'WIP'";
        b        = "!f() { git fetch origin --prune && git checkout -b \"$1\" origin/main; }; f";
        rebom    = "rebase origin/main";
        foprebom = "!git fetch origin --prune && git rebase origin/main";
        fop      = "push --force-with-lease --force-if-includes";
        gone     = "!git branch -v | grep '\\[gone\\]' | awk '{print $1}'";
        cleanup  = "!git branch -v | grep '\\[gone\\]' | awk '{print $1}' | xargs -r git branch -D";
        squash   = "!f() { base=$(git merge-base HEAD origin/main); if [ -n \"$1\" ]; then GIT_SEQUENCE_EDITOR='sed -i 2,\\$s/^pick/fixup/' git rebase -i \"$base\" && git commit --amend -m \"$1\"; else GIT_SEQUENCE_EDITOR='sed -i 2,\\$s/^pick/squash/' git rebase -i \"$base\"; fi; }; f";
      };
    };
    ignores = [
      ".DS_Store" "*.swp" ".direnv" ".env"
      "node_modules" "__pycache__" "*.pyc" ".venv" "result"
    ];
  };

  programs.gpg.enable = true;

  services.gpg-agent = {
    enable   = true;
    pinentry.package = pkgs.pinentry-qt;
    enableSshSupport = false;
  };

  programs.bat.enable = true;
  catppuccin.bat.enable = true;

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate     = true;
      side-by-side = true;
      line-numbers = true;
      syntax-theme = "Catppuccin Mocha";
    };
  };
}
