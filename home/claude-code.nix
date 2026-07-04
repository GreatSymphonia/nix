{ unstable, ... }: {
  programs.claude-code = {
    enable = true;
    package = unstable.claude-code;

    settings = {
      theme = "dark";
      effortLevel = "medium";
    };
  };
}
