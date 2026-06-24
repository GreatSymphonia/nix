{ pkgs, ... }: {
  programs.git = {
    enable = true;
    settings = {
      user.name  = "Louis Raymond";
      user.email = "louis.raymond2017@gmail.com";
      init.defaultBranch = "main";
      pull.rebase        = true;
      push.autoSetupRemote = true;
      core = {
        editor     = "micro";
        autocrlf   = "input";
      };
      diff.colorMoved = "zebra";
      merge.conflictstyle = "diff3";
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
        fop      = "push --force-with-lease";
        gone     = "!git branch -v | grep '\\[gone\\]' | awk '{print $1}'";
        cleanup  = "!git branch -v | grep '\\[gone\\]' | awk '{print $1}' | xargs git branch -D";
      };
    };
    ignores = [
      ".DS_Store" "*.swp" ".direnv" ".env"
      "node_modules" "__pycache__" "*.pyc" ".venv" "result"
    ];
  };

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
