{ pkgs, ... }:

{
  catppuccin.waybar.enable = true;

  programs.waybar = {
    enable = true;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 24;
      modules-left = [
        "sway/workspaces"
        "sway/mode"
      ];
      modules-center = [ "clock" ];
      # Audio et réseau ne sont plus des modules texte waybar : nm-applet et
      # pasystray (démarrés via exec) apparaissent dans le tray avec un
      # vrai menu interactif au clic, comme les applets Plasma. Les modules
      # restants sont réduits à l'icône.
      modules-right = [
        "custom/notification"
        "custom/battery"
        "tray"
      ];

      "sway/workspaces".disable-scroll = true;
      clock = {
        format = "{:%H:%M}";
        tooltip-format = "{calendar}";
      };
      # Icône batterie "à la KDE" : clic molette = désactive/réactive la
      # veille (verrouillage + dpms) automatique ; clic gauche = change de
      # profil d'alimentation (secondaire).
      "custom/battery" = {
        exec = "${pkgs.sway-scripts}/bin/battery-status";
        return-type = "json";
        interval = 15;
        signal = 8;
        on-click = "${pkgs.sway-scripts}/bin/cycle-power-profile";
        on-click-middle = "${pkgs.sway-scripts}/bin/toggle-idle-inhibit";
      };
      # Centre de notifications (swaync) : l'icône change quand une
      # notification est en attente ; clic gauche ouvre le panneau
      # d'historique, clic droit bascule le mode "Ne pas déranger".
      "custom/notification" = {
        tooltip = false;
        format = "{icon}";
        format-icons = {
          notification = "<span foreground='#f38ba8'><sup></sup></span>";
          none = "";
          dnd-notification = "<span foreground='#f38ba8'><sup></sup></span>";
          dnd-none = "";
        };
        return-type = "json";
        exec-if = "which swaync-client";
        exec = "${pkgs.swaynotificationcenter}/bin/swaync-client -swb";
        on-click = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
        on-click-right = "${pkgs.swaynotificationcenter}/bin/swaync-client -d -sw";
        escape = true;
      };
      tray.spacing = 10;
    };

    style = ''
      * {
        /* Fira Code pour le texte ; repli sur la variante Nerd Font pour
           les glyphes d'icônes (batterie, rétroéclairage) qu'elle ne
           contient pas. */
        font-family: "Fira Code", "FiraCode Nerd Font";
        font-size: 12px;
        min-height: 0;
      }

      /* catppuccin.waybar ne définit que les variables de couleur (@base,
         @text, ...) — il faut les appliquer explicitement pour avoir un
         vrai fond sombre (sinon on hérite du thème GTK clair par défaut). */
      window#waybar {
        background-color: @base;
        color: @text;
        padding: 0 6px;
      }

      #workspaces button {
        color: @subtext0;
        background-color: transparent;
        padding: 0 8px;
        margin: 2px 3px;
        border-radius: 6px;
      }
      #workspaces button.focused {
        color: @base;
        background-color: @blue;
      }
      #workspaces button.urgent {
        color: @base;
        background-color: @red;
      }

      #mode,
      #custom-battery,
      #tray {
        color: @text;
        padding: 0 8px;
        margin: 2px 3px;
      }

      /* Veille désactivée via clic molette sur l'icône batterie. */
      #custom-battery.inhibited {
        color: @yellow;
      }
      #custom-battery.charging {
        color: @green;
      }

      #clock {
        color: @blue;
        font-weight: bold;
        padding: 0 8px;
        margin: 2px 3px;
      }
    '';
  };

  # Garde-fou : waybar est lancée par `bar { swaybar_command waybar }`, donc
  # sway ne la relance jamais toute seule si elle meurt. Or un
  # `nixos-rebuild switch` provoque parfois un SIGSEGV en rafale de plusieurs
  # process GUI (waybar, nm-applet, xdg-desktop-portal-gtk...) au moment où
  # la session graphique est rechargée. Ce service surveille waybar et
  # déclenche un `swaymsg reload` si elle a disparu.
  systemd.user.services.waybar-watchdog = {
    Unit = {
      Description = "Relance waybar si elle crashe (ex: pendant un nixos-rebuild switch)";
      After = [ "sway-session.target" ];
      PartOf = [ "sway-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.writeShellScript "waybar-watchdog" ''
        set -euo pipefail
        while true; do
          # Le wrapper Nix renomme le process en ".waybar-wrapped" (visible
          # dans /proc/*/comm), pas "waybar" — pgrep -x échouerait toujours
          # et déclencherait un reload en boucle. Pas de -x ici : on veut
          # matcher aussi bien "waybar" que ".waybar-wrapped".
          if ! ${pkgs.procps}/bin/pgrep waybar >/dev/null; then
            ${pkgs.sway}/bin/swaymsg reload || true
          fi
          sleep 5
        done
      ''}";
      Restart = "always";
      RestartSec = 2;
    };
    Install.WantedBy = [ "sway-session.target" ];
  };
}
