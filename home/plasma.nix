{ pkgs, ... }:
{
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
      krunner._launch = "Meta";

      plasmashell."activate application launcher" = "Alt+F1";
      plasmashell."activate task manager entry 1" = "Meta+1";
      plasmashell."activate task manager entry 2" = "Meta+2";
      plasmashell."activate task manager entry 3" = "Meta+3";

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
      # Panneau supérieur : horloge, espaceur, Bluetooth, zone de notification.
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
