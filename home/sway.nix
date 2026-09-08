{ pkgs, ... }:

let
  terminal = "${pkgs.ghostty}/bin/ghostty";
  menu = "${pkgs.wofi}/bin/wofi --show drun";
  lock = "${pkgs.swaylock}/bin/swaylock -f";
  screenshotRegion = pkgs.writeShellScriptBin "screenshot-region" ''
    ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.swappy}/bin/swappy -f -
  '';
  screenshotFull = pkgs.writeShellScriptBin "screenshot-full" ''
    ${pkgs.grim}/bin/grim - | ${pkgs.swappy}/bin/swappy -f -
  '';
in
{
  catppuccin.waybar.enable = true;
  catppuccin.mako.enable = true;

  home.packages = with pkgs; [
    grim
    slurp
    swappy
    wl-clipboard
    cliphist
    brightnessctl
    playerctl
    pavucontrol
    kdePackages.polkit-kde-agent-1
    screenshotRegion
    screenshotFull
  ];

  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    xwayland = true;
    config = null;
    # Le check statique tourne dans le sandbox Nix (pas de $HOME réel) et
    # échoue sur l'accès au fond d'écran / au cache fontconfig.
    checkConfig = false;

    extraConfig = ''
      set $mod Mod4
      set $left h
      set $down j
      set $up k
      set $right l

      font pango:FiraCode Nerd Font 10

      # --- Écrans : mapping 1:1 de la disposition KDE actuelle -------------
      # (kscreen-doctor -o) : DP-11 gauche, DP-9 centre, DP-10 droite,
      # 1920x1080 sur les trois, chacun à son taux natif EDID.
      output "DP-11" position 0 0 resolution 1920x1080@74.910Hz
      output "DP-9"  position 1920 0 resolution 1920x1080@99.900Hz
      output "DP-10" position 3840 0 resolution 1920x1080@74.910Hz

      # eDP-1 (écran interne) désactivé par défaut : setup actuel = laptop
      # docké, écran fermé. Réactiver au besoin avec :
      #   swaymsg output eDP-1 enable
      output "eDP-1" disable

      output * bg /home/louis/Pictures/Wallpaper.jpg fill

      input type:keyboard {
        xkb_layout us(intl)
      }
      input type:touchpad {
        tap enabled
        natural_scroll enabled
      }

      # --- Apparence ---------------------------------------------------------
      default_border pixel 2
      gaps inner 4
      client.focused          #89b4fa #1e1e2e #cdd6f4 #89b4fa #89b4fa
      client.unfocused        #313244 #1e1e2e #a6adc8 #313244 #313244
      client.focused_inactive #313244 #1e1e2e #a6adc8 #313244 #313244

      # --- Barre : waybar remplace les panneaux Plasma top/bottom ------------
      bar {
        swaybar_command waybar
      }

      # --- Démarrage automatique ---------------------------------------------
      exec ${pkgs.mako}/bin/mako
      exec ${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1

      # ======================= Raccourcis (calqués sur KDE) ===================

      # Verrouillage / déconnexion — Meta+L et Ctrl+Alt+Del comme sous KDE.
      bindsym $mod+l exec ${lock}
      bindsym Ctrl+Alt+Delete exec swaynag -m 'Quitter Sway ?' -b 'Quitter' 'swaymsg exit'

      # Lanceur — Meta seul ouvre wofi, comme KRunner sous KDE (Meta seul).
      bindsym --release $mod exec ${menu}
      # Alt+F1 — équivalent du "activate application launcher" Plasma.
      bindsym Mod1+F1 exec ${menu}

      # Terminal / fermeture de fenêtre.
      bindsym $mod+Return exec ${terminal}
      bindsym Ctrl+Alt+t exec ${terminal}
      bindsym $mod+e exec dolphin
      bindsym Mod1+F4 kill

      # Navigation entre fenêtres — Alt+Tab / Alt+Shift+Tab, comme
      # "Walk Through Windows" sous KWin. Sway n'a pas de pile MRU native :
      # ceci fait défiler les fenêtres du groupe courant dans l'ordre du
      # layout, pas dans l'ordre d'utilisation récente comme KWin.
      bindsym Mod1+Tab focus next
      bindsym Mod1+Shift+Tab focus prev

      # Focus / déplacement de fenêtres (équivalent hjkl + flèches).
      bindsym $mod+$left  focus left
      bindsym $mod+$down  focus down
      bindsym $mod+$up    focus up
      bindsym $mod+$right focus right
      bindsym $mod+Left  focus left
      bindsym $mod+Down  focus down
      bindsym $mod+Up    focus up
      bindsym $mod+Right focus right

      bindsym $mod+Shift+$left  move left
      bindsym $mod+Shift+$down  move down
      bindsym $mod+Shift+$up    move up
      bindsym $mod+Shift+$right move right

      # Plein écran — le plus proche de "Window Maximize" (Meta+PgUp) en
      # tuilé. Meta+PgDown n'a pas d'équivalent "minimize" en tuilé : mappé
      # sur scratchpad (cache la fenêtre, à rappeler avec Meta+Shift+PgDown).
      bindsym $mod+Prior fullscreen toggle
      bindsym $mod+Next  move scratchpad
      bindsym $mod+Shift+Next scratchpad show

      # Bascule flottant/tuilé + redimensionnement rapide (mode resize).
      bindsym $mod+Shift+space floating toggle
      bindsym $mod+r mode "resize"
      mode "resize" {
        bindsym $left  resize shrink width 20px
        bindsym $down  resize grow height 20px
        bindsym $up    resize shrink height 20px
        bindsym $right resize grow width 20px
        bindsym Escape mode "default"
        bindsym Return mode "default"
      }

      # Workspaces — Meta+1/2/3 (parité avec les raccourcis "task manager
      # entry 1/2/3" de Plasma, mais ici ce sont des espaces de travail).
      bindsym $mod+1 workspace 1
      bindsym $mod+2 workspace 2
      bindsym $mod+3 workspace 3
      bindsym $mod+4 workspace 4
      bindsym $mod+Shift+1 move container to workspace 1
      bindsym $mod+Shift+2 move container to workspace 2
      bindsym $mod+Shift+3 move container to workspace 3
      bindsym $mod+Shift+4 move container to workspace 4

      # Capture d'écran — équivalent Spectacle (grim+slurp+swappy).
      bindsym Print exec screenshot-full
      bindsym $mod+Print exec screenshot-region
      bindsym Shift+Print exec screenshot-region

      # Volume / luminosité — identiques aux touches multimédias KDE.
      bindsym XF86AudioMute exec ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle
      bindsym XF86AudioRaiseVolume exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%
      bindsym XF86AudioLowerVolume exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%
      bindsym XF86MonBrightnessUp exec ${pkgs.brightnessctl}/bin/brightnessctl set +5%
      bindsym XF86MonBrightnessDown exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%-
      bindsym XF86AudioPlay exec ${pkgs.playerctl}/bin/playerctl play-pause
      bindsym XF86AudioNext exec ${pkgs.playerctl}/bin/playerctl next
      bindsym XF86AudioPrev exec ${pkgs.playerctl}/bin/playerctl previous
    '';
  };

  programs.waybar = {
    enable = true;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 24;
      modules-left = [ "sway/workspaces" "sway/mode" ];
      modules-center = [ "clock" ];
      modules-right = [
        "idle_inhibitor"
        "pulseaudio"
        "network"
        "backlight"
        "battery"
        "bluetooth"
        "tray"
      ];

      "sway/workspaces".disable-scroll = true;
      clock = {
        format = "{:%Y-%m-%d %H:%M}";
        tooltip-format = "{calendar}";
      };
      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "🔇";
        format-icons = { default = [ "🔈" "🔉" "🔊" ]; };
        on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
      };
      network = {
        format-wifi = "📶 {essid}";
        format-ethernet = "🖧 {ipaddr}";
        format-disconnected = "⚠ déconnecté";
      };
      battery = {
        format = "{icon} {capacity}%";
        format-icons = [ "" "" "" "" "" ];
      };
      backlight.format = "☀ {percent}%";
      bluetooth.format = "";
      tray.spacing = 8;
    };

    style = ''
      * {
        font-family: "FiraCode Nerd Font";
        font-size: 12px;
      }
    '';
  };

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
        font-family: "FiraCode Nerd Font";
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

  services.mako = {
    enable = true;
    settings = {
      default-timeout = 6000;
      border-radius = 8;
      font = "FiraCode Nerd Font 10";
    };
  };

  programs.swaylock = {
    enable = true;
    settings = {
      color = "1e1e2e";
      inside-color = "1e1e2e";
      ring-color = "89b4fa";
      text-color = "cdd6f4";
      ignore-empty-password = true;
    };
  };

  services.swayidle = {
    enable = true;
    timeouts = [
      { timeout = 300; command = "${pkgs.swaylock}/bin/swaylock -f"; }
      {
        timeout = 600;
        command = "swaymsg 'output * dpms off'";
        resumeCommand = "swaymsg 'output * dpms on'";
      }
    ];
    events = {
      before-sleep = "${pkgs.swaylock}/bin/swaylock -f";
    };
  };
}
