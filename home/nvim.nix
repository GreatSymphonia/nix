{ config, pkgs, lib, ... }:

{
  # Neovim + dépendances requises par LazyVim et ses plugins par défaut
  home.packages = with pkgs; [
    neovim
    lazygit      # intégration git dans LazyVim
  ];

  home.sessionVariables.EDITOR = "nvim";

  home.activation.lazyvimStarter = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    NVIM_CONFIG="$HOME/.config/nvim"
    if [ ! -d "$NVIM_CONFIG" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://github.com/LazyVim/starter "$NVIM_CONFIG"
      $DRY_RUN_CMD rm -rf "$NVIM_CONFIG/.git"
    fi
  '';
}
