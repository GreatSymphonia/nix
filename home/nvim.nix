{ pkgs, lib, ... }:

{
  # Neovim + dépendances requises par LazyVim et ses plugins par défaut.
  home.packages = with pkgs; [
    neovim
    lazygit
  ];

  # Exception assumée : LazyVim starter est cloné au premier switch plutôt que
  # géré déclarativement, pour conserver le mode d'édition upstream.
  home.activation.lazyvimStarter = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    NVIM_CONFIG="$HOME/.config/nvim"
    if [ ! -d "$NVIM_CONFIG" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://github.com/LazyVim/starter "$NVIM_CONFIG"
      $DRY_RUN_CMD rm -rf "$NVIM_CONFIG/.git"
    fi
  '';
}
