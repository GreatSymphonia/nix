{ pkgs, ... }: {
  programs.obsidian = {
    enable = true;
    package = pkgs.unstable.obsidian;

    vaults.main = {
      target = "Obsidian";

      settings.themes = [ pkgs.obsidianThemes.catppuccin ];

      settings.communityPlugins = with pkgs.obsidianPlugins; [
        advanced-canvas
        calendar
        canvas-send-to-back
        code-styler
        dataview
        drawio-obsidian
        obsidian-excalidraw-plugin
        folders2graph
        grammalecte
        graph-files-highlight-sync
        obsidian-icon-shortcodes
        obsidian-kanban
        obsidian-latex-suite
        live-wallpaper
        share-my-plugin-list
        start-page
        obsidian-tasks-plugin
        templater-obsidian
      ];
    };
  };
}
