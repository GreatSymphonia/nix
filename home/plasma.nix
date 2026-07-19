{ pkgs, ... }:

let
  # "Command Output" plasmoid by Zren — runs a shell command periodically and
  # renders its output as panel text. Used here to show live Claude Code
  # usage (via ccusage) next to the system tray.
  # https://github.com/Zren/plasma-applet-commandoutput
  commandOutputPlasmoid = pkgs.stdenvNoCC.mkDerivation {
    pname = "plasma-applet-commandoutput";
    version = "unstable-2026-07-19";

    src = pkgs.fetchFromGitHub {
      owner = "Zren";
      repo = "plasma-applet-commandoutput";
      rev = "b2b5a3f05a5613fd4f57f448c34814f65e18a21f";
      sha256 = "1zwg6b9ck285m4m80nhr0q20bd0r9bqp9lypv6cbsr96h4wrw1bq";
    };

    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/plasma/plasmoids/com.github.zren.commandoutput
      cp -r package/* $out/share/plasma/plasmoids/com.github.zren.commandoutput/
      runHook postInstall
    '';
  };

  # Prints a compact "▓▓▓▓░░░░░░ NN%" gauge of the active Claude Code 5h
  # usage block, sourced from ccusage (reads local ~/.claude/projects/*.jsonl,
  # no API key needed). Pass "tooltip" for a multi-line breakdown.
  #
  # Anthropic doesn't publish an exact token quota for Claude Pro, so the
  # percentage is self-calibrated: it's the current block's token count
  # relative to your own heaviest completed 5h block over the last 14 days
  # (i.e. "how loaded is this block compared to my usual heavy sessions"),
  # not a precise fraction of the real plan limit.
  claudeUsageWidget = pkgs.writeShellApplication {
    name = "claude-usage-widget";
    runtimeInputs = [
      pkgs.nodejs
      pkgs.jq
      pkgs.coreutils
      pkgs.gawk
    ];
    text = ''
      export LC_ALL=C
      mode="''${1:-label}"

      active_json="$(npx --yes ccusage@20.0.17 blocks --active --json --offline 2>/dev/null || echo '{"blocks":[]}')"

      if [ "$(echo "$active_json" | jq '.blocks | length')" = "0" ]; then
        if [ "$mode" = "tooltip" ]; then
          echo "Aucun bloc Claude Code actif"
        else
          echo "--"
        fi
        exit 0
      fi

      current_tokens=$(echo "$active_json" | jq -r '.blocks[0].totalTokens')
      remaining=$(echo "$active_json" | jq -r '.blocks[0].projection.remainingMinutes')

      since=$(date -d '14 days ago' +%Y%m%d)
      history_json="$(npx --yes ccusage@20.0.17 blocks --since "$since" --json --offline 2>/dev/null || echo '{"blocks":[]}')"
      max_tokens=$(echo "$history_json" | jq -r '[.blocks[] | select(.isGap != true) | .totalTokens] | max // 1')
      [ "$max_tokens" -lt 1 ] && max_tokens=1

      pct=$(( current_tokens * 100 / max_tokens ))
      [ "$pct" -gt 100 ] && pct=100

      filled=$(( pct / 10 ))
      empty=$(( 10 - filled ))
      filled_blocks=""
      for _ in $(seq 1 "$filled"); do filled_blocks="''${filled_blocks}█"; done
      empty_blocks=""
      for _ in $(seq 1 "$empty"); do empty_blocks="''${empty_blocks}█"; done

      # Same glyph (█) for filled and empty segments, distinguished purely by
      # color, so the bar doesn't depend on a font's glyph design for ░
      # (which is a stipple/dot pattern by Unicode definition, not a paler
      # solid block, in most fonts including Nerd Font patched ones).
      # Catppuccin Mocha: blue for filled, surface2 for empty.
      bar="<font color=\"#89b4fa\">''${filled_blocks}</font><font color=\"#585b70\">''${empty_blocks}</font>"

      # Compact "1.2k" / "3.4M" token notation.
      fmt_tokens() {
        awk -v n="$1" 'BEGIN {
          if (n >= 1000000) printf "%.1fM", n / 1000000;
          else if (n >= 1000) printf "%.1fk", n / 1000;
          else printf "%d", n;
        }'
      }
      current_fmt=$(fmt_tokens "$current_tokens")
      max_fmt=$(fmt_tokens "$max_tokens")

      # "hh:mm" remaining time.
      remaining_hhmm=$(printf '%02d:%02d' $(( remaining / 60 )) $(( remaining % 60 )))

      if [ "$mode" = "tooltip" ]; then
        printf 'Utilisation : %s%%\nJetons : %s / %s\nTemps restant : %s\n' \
          "$pct" "$current_fmt" "$max_fmt" "$remaining_hhmm"
      else
        printf '%s %s%%\n' "$bar" "$pct"
      fi
    '';
  };
in

{
  home.packages = [
    commandOutputPlasmoid
    claudeUsageWidget
  ];

  programs.plasma = {
    enable = true;

    shortcuts = {
      "ksmserver"."Lock Session" = [
        "Meta+L"
        "Screensaver"
      ];
      "ksmserver"."Log Out" = "Ctrl+Alt+Del";

      kwin."Walk Through Windows" = "Alt+Tab";
      kwin."Walk Through Windows (Reverse)" = "Alt+Shift+Tab";

      kwin."Window Close" = "Alt+F4";
      kwin."Window Maximize" = "Meta+PgUp";
      kwin."Window Minimize" = "Meta+PgDown";

      kwin."Window Quick Tile Left" = "Meta+Left";
      kwin."Window Quick Tile Right" = "Meta+Right";
      kwin."Window Quick Tile Top" = "Meta+Up";
      kwin."Window Quick Tile Bottom" = "Meta+Down";

      kwin.Overview = "Meta+Tab";
      kwin."Grid View" = "Meta+Shift+Tab";
      krunner._launch = [ ];

      plasmashell."activate application launcher" = "Alt+F1";
      plasmashell."activate task manager entry 1" = "Meta+1";
      plasmashell."activate task manager entry 2" = "Meta+2";
      plasmashell."activate task manager entry 3" = "Meta+3";

      services."org.kde.krunner.desktop" = "Meta";
      "services/krunner.desktop"._launch = "Meta";
      "services/org.kde.krunner.desktop"._launch = "Meta";

      kmix.mute = "Volume Mute";
      kmix.increase_volume = "Volume Up";
      kmix.decrease_volume = "Volume Down";
    };

    configFile = {
      kdeglobals = {
        General = {
          TerminalApplication = "${pkgs.ghostty}/bin/ghostty --gtk-single-instance=true";
          TerminalService = "com.mitchellh.ghostty.desktop";
        };

        KDE = {
          AnimationDurationFactor = 0;
          widgetStyle = "Breeze";
        };

        Icons.Theme = "candy-icons";

        WM = {
          activeBackground = "30,30,46";
          inactiveBackground = "30,30,46";
          activeForeground = "205,214,244";
          inactiveForeground = "186,194,222";
        };
      };

      kwinrc = {
        Desktops = {
          Number = 1;
          Rows = 1;
        };

        Tiling.padding = 4;

        Xwayland.Scale = 1.35;
        ModifierOnlyShortcuts.Meta = "org.kde.krunner,/App,org.kde.krunner.App,display";
      };

      krunnerrc.General = {
        FreeFloating = true;
        historyBehavior = "ImmediateCompletion";
      };

      ksplashrc.KSplash.Theme = "a2n.kuro";

      plasma-localerc.Formats.LANG = "fr_CA.UTF-8";

      spectaclerc = {
        ImageSave.translatedScreenshotsFolder = "Copies d'écran";
        VideoSave.translatedScreencastsFolder = "Copies d'écran";
      };

      baloofilerc.General = {
        dbVersion = 2;
      };
    };

    workspace = {
      wallpaper = "/home/louis/Pictures/Wallpaper.jpg";
    };

    panels = [
      # Top panel: clock, spacer, bluetooth, Claude usage widget, system tray.
      {
        location = "top";
        height = 24;
        widgets = [
          {
            name = "org.kde.plasma.digitalclock";
            config."Agenda".showWeekNumbers = true;
          }
          "org.kde.plasma.panelspacer"
          {
            name = "com.github.zren.commandoutput";
            config."General" = {
              command = "${claudeUsageWidget}/bin/claude-usage-widget";
              tooltipCommand = "${claudeUsageWidget}/bin/claude-usage-widget tooltip";
              interval = 60000;
              showBackground = false;
              useFixedWidth = false;
              fontFamily = "FiraCode Nerd Font Mono";
              fontSize = 10;
            };
          }
          {
            name = "org.kde.plasma.bluetooth";
          }
          {
            systemTray = {
              items = {
                extra = [
                  "org.kde.plasma.cameraindicator"
                  "org.kde.plasma.clipboard"
                  "org.kde.plasma.manage-inputmethod"
                  "org.kde.plasma.keyboardlayout"
                  "org.kde.plasma.devicenotifier"
                  "org.kde.plasma.mediacontroller"
                  "org.kde.plasma.notifications"
                  "org.kde.plasma.battery"
                  "org.kde.kscreen"
                  "org.kde.plasma.volume"
                  "org.kde.plasma.networkmanagement"
                  "org.kde.plasma.brightness"
                  "org.kde.plasma.printmanager"
                  "org.kde.plasma.keyboardindicator"
                  "org.kde.plasma.weather"
                ];
              };
            };
          }
        ];
      }

      # Bottom panel: launcher + task manager.
      {
        location = "bottom";
        height = 40;
        floating = true;
        alignment = "center";
        lengthMode = "fit";
        hiding = "autohide";
        widgets = [
          "org.kde.plasma.kickoff"
          {
            name = "org.kde.plasma.icontasks";
            config."General" = {
              launchers = "applications:systemsettings.desktop,applications:zen.desktop,applications:org.kde.dolphin.desktop,applications:com.discordapp.Discord.desktop,applications:com.mitchellh.ghostty.desktop,applications:code.desktop";
            };
          }
        ];
      }
    ];
  };
}
