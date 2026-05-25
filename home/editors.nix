{ pkgs, unstable, ... }: {
  programs.vscode = {
    enable = true;
    package = unstable.vscode;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        # Thème
        catppuccin.catppuccin-vsc
        catppuccin.catppuccin-vsc-icons

        # Git
        github.vscode-pull-request-github

        # Formatters / Linters
        esbenp.prettier-vscode
        dbaeumer.vscode-eslint
        redhat.vscode-yaml

        # Langages
        redhat.ansible
        ms-python.python
        # ms-python.vscode-python-envs
        ms-vscode.cpptools
        redhat.java
        jnoortheen.nix-ide
        mkhl.direnv

        # Remote / Containers
        ms-vscode-remote.remote-ssh
        ms-vscode.remote-explorer
        ms-azuretools.vscode-docker
        ms-kubernetes-tools.vscode-kubernetes-tools

        # Diagrammes
        hediet.vscode-drawio
        jebbs.plantuml

        # IA
        github.copilot
        github.copilot-chat

        # Qualité de vie
        usernamehw.errorlens
      ];

      userSettings = {
        # Thème
        "workbench.colorTheme"    = "Catppuccin Mocha";
        "workbench.iconTheme"     = "catppuccin-mocha";
        "workbench.sideBar.location" = "right";
        "workbench.startupEditor" = "none";

        # Police — partout
        "editor.fontFamily"               = "'FiraCode Nerd Font', 'monospace'";
        "editor.fontSize"                 = 12;
        "editor.fontLigatures"            = true;
        "editor.fontWeight"               = "300";
        "editor.codeLensFontFamily"       = "'FiraCode Nerd Font'";
        "editor.inlayHints.fontFamily"    = "'FiraCode Nerd Font'";
        "editor.inlineSuggest.fontFamily" = "'FiraCode Nerd Font'";
        "debug.console.fontFamily"        = "'FiraCode Nerd Font'";
        "markdown.preview.fontFamily"     = "'FiraCode Nerd Font'";
        "scm.inputFontFamily"             = "'FiraCode Nerd Font'";
        "terminal.integrated.fontFamily"  = "'FiraCode Nerd Font'";
        "terminal.integrated.fontSize"    = 12;
        "terminal.integrated.fontLigatures.enabled" = true;
        "terminal.external.linuxExec"     = "ghostty";

        # Éditeur
        "editor.lineNumbers"              = "relative";
        "editor.rulers"                   = [ 80 120 ];
        "editor.tabSize"                  = 2;
        "editor.wordWrap"                 = "off";
        "editor.formatOnSave"             = true;
        "editor.renderWhitespace"         = "all";
        "editor.suggestSelection"         = "first";
        "editor.bracketPairColorization.enabled" = true;
        "editor.guides.bracketPairs"      = true;
        "editor.inlineSuggest.enabled"    = true;
        "editor.accessibilitySupport"     = "off";
        "editor.largeFileOptimizations"   = false;
        "editor.semanticHighlighting.enabled" = true;
        "editor.unicodeHighlight.invisibleCharacters" = false;

        # Fichiers
        "files.autoSave"                  = "onFocusChange";
        "files.associations" = {
          "*.yml"  = "yaml";
          "*.yaml" = "yaml";
          "*.j2"   = "jinja-cisco";
          "*.ios"  = "jinja-cisco";
        };

        # Git
        "git.autofetch"                   = true;
        "git.confirmSync"                 = false;
        "git.enableSmartCommit"           = true;
        "git.openRepositoryInParentFolders" = "never";
        "git.ignoreRebaseWarning"         = true;
        "git.replaceTagsWhenPull"         = true;

        # Nix
        "nix.enableLanguageServer"        = true;

        # C/C++
        "C_Cpp.default.cppStandard"       = "c++20";
        "C_Cpp.default.cStandard"         = "c11";
        "C_Cpp.autocompleteAddParentheses" = true;
        "C_Cpp.clang_format_sortIncludes" = true;
        "C_Cpp.addNodeAddonIncludePaths"  = true;
        "[cpp]"."editor.defaultFormatter" = "ms-vscode.cpptools";
        "[c]"."editor.defaultFormatter"   = "ms-vscode.cpptools";

        # Python
        "python.analysis.typeCheckingMode" = "standard";
        "[python]"."editor.formatOnType"  = true;

        # Java
        "[java]"."editor.defaultFormatter" = "redhat.java";

        # YAML / Docker / Ansible
        "[dockercompose]" = {
          "editor.insertSpaces"    = true;
          "editor.tabSize"         = 2;
          "editor.autoIndent"      = "advanced";
          "editor.defaultFormatter" = "redhat.vscode-yaml";
          "editor.quickSuggestions" = {
            "other"    = true;
            "comments" = false;
            "strings"  = true;
          };
        };
        "[github-actions-workflow]"."editor.defaultFormatter" = "redhat.vscode-yaml";
        "[ansible]" = {
          "editor.tabFocusMode"      = false;
          "editor.detectIndentation" = true;
          "editor.insertSpaces"      = true;
          "editor.tabSize"           = 2;
          "editor.autoIndent"        = "advanced";
          "editor.quickSuggestions"  = {
            "comments" = true;
            "other"    = true;
            "strings"  = true;
          };
        };

        # Dart / Flutter
        "[dart]" = {
          "editor.formatOnSave"    = true;
          "editor.formatOnType"    = true;
          "editor.rulers"          = [ 80 ];
          "editor.selectionHighlight" = false;
          "editor.suggest.snippetsPreventQuickSuggestions" = false;
          "editor.suggestSelection" = "first";
          "editor.tabCompletion"   = "onlySnippets";
          "editor.wordBasedSuggestions" = "off";
        };

        # Divers
        "cmake.configureOnOpen"           = false;
        "makefile.configureOnOpen"        = false;
        "explorer.confirmDelete"          = false;
        "explorer.confirmDragAndDrop"     = false;
        "redhat.telemetry.enabled"        = false;
        "security.workspace.trust.untrustedFiles" = "open";
        "json.maxItemsComputed"           = 20000;
        "remote.autoForwardPortsSource"   = "hybrid";
        "remote.SSH.connectTimeout"       = 1800;
        "terminal.integrated.enableMultiLinePasteWarning" = "never";
        "terminal.integrated.initialHint" = false;
        "terminal.integrated.shellIntegration.enabled" = true;
        "terminal.integrated.defaultProfile.linux" = "bash";
        "terminal.integrated.profiles.linux" = {
          "bash" = { "path" = "bash"; "icon" = "terminal-bash"; };
        };
        "window.commandCenter"            = false;
        "window.zoomPerWindow"            = false;
        "workbench.editor.empty.hint"     = "hidden";
        "chat.tips.enabled"               = false;
        "github.copilot.nextEditSuggestions.enabled" = true;
        "typescript.updateImportsOnFileMove.enabled" = "always";
        "liveServer.settings.donotShowInfoMsg"        = true;
        "liveServer.settings.donotVerifyTags"         = true;
        "plantuml.urlFormat"              = "png";
        "plantuml.diagramsRoot"           = "UML";
        "hediet.vscode-drawio.theme"      = "dark";
        "hediet.vscode-drawio.appearance" = "dark";
        "markdown.links.openLocation"     = "beside";
        "markdown-preview-enhanced.previewTheme" = "atom-dark.css";
        "vscode-kubernetes.log-viewer.destination" = "Terminal";
        "docker.extension.enableComposeLanguageServer" = false;
      };
    };
  };
}
