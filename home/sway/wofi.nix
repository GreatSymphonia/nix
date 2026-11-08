{ ... }:

{
  programs.wofi = {
    enable = true;
    settings = {
      width = 600;
      height = 400;
      show = "drun";
      prompt = "Rechercher…";
    };
    style = ''
      window {
        font-family: "Fira Code", "FiraCode Nerd Font";
        font-size: 13px;
        background-color: #1e1e2e;
        color: #cdd6f4;
        border: 2px solid #89b4fa;
        border-radius: 8px;
      }
      #input {
        background-color: #313244;
        color: #cdd6f4;
        border: none;
        border-radius: 6px;
        margin: 6px;
      }
      #entry:selected {
        background-color: #45475a;
        border-radius: 6px;
      }
      #text {
        color: #cdd6f4;
      }
    '';
  };
}
