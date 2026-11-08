{ pkgs, ... }:

let
  terminal = "${pkgs.ghostty}/bin/ghostty";
  lock = "${pkgs.swaylock}/bin/swaylock -f";
  scripts = pkgs.sway-scripts;
in
{
  imports = [
    ./idle.nix
    ./swaync.nix
    ./waybar.nix
    ./wofi.nix
  ];

  home.packages = with pkgs; [
    scripts
    grim
    slurp
    swappy
    wl-clipboard
    cliphist
    brightnessctl
    playerctl
    pavucontrol
    jq
    networkmanagerapplet
    pasystray
    kdePackages.polkit-kde-agent-1
    power-profiles-daemon
    gawk
    gnugrep
    libnotify
    openssh
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
        xkb_layout "ca"
        xkb_variant "multix"
      }
      input type:touchpad {
        tap enabled
        natural_scroll enabled
      }

      # La fenêtre factice utilisée par l'icône batterie de waybar (clic
      # molette, inhibition de la veille) est gérée entièrement dans
      # toggle-idle-inhibit : `for_window` s'évalue trop tôt (avant que
      # Ghostty n'ait appliqué --title) pour cibler cette fenêtre de façon
      # fiable, donc inhibit_idle/scratchpad sont appliqués par le script
      # lui-même une fois la fenêtre confirmée mappée.

      # --- Apparence ---------------------------------------------------------
      default_border pixel 2
      gaps inner 4
      client.focused          #89b4fa #1e1e2e #cdd6f4 #89b4fa #89b4fa
      client.unfocused        #313244 #1e1e2e #a6adc8 #313244 #313244
      client.focused_inactive #313244 #1e1e2e #a6adc8 #313244 #313244

      # --- Barre : waybar remplace les panneaux Plasma top/bottom ------------
      bar {
        swaybar_command waybar
        output "DP-9"
      }

      # --- Démarrage automatique ---------------------------------------------
      # Notifications : services.swaync démarre le démon via son propre
      # service systemd --user, pas besoin d'un exec ici.
      exec ${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1
      # Trousseau KDE (org.freedesktop.secrets) — sous Plasma, kwalletd est
      # démarré par le login PAM, mais ce mécanisme ne s'accroche pas
      # correctement à la session sway. On le relance explicitement ici.
      exec ${pkgs.kdePackages.kwallet}/bin/kwalletd6
      # Icônes de tray avec menus interactifs (équivalent des applets Plasma
      # réseau / audio) : cliquer donne un vrai menu.
      exec ${pkgs.networkmanagerapplet}/bin/nm-applet --indicator
      exec ${pkgs.pasystray}/bin/pasystray
      exec ${pkgs.blueman}/bin/blueman-applet

      # ======================= Raccourcis (calqués sur KDE) ===================

      # Menu de session (verrouiller/suspendre/déconnexion/redémarrer/
      # éteindre) — Ctrl+Alt+Del comme le "Leave..." de KDE.
      bindsym Ctrl+Alt+Delete exec ${scripts}/bin/session-menu

      # Lanceur SSH — liste les hôtes de ~/.ssh/config dans wofi.
      bindsym $mod+Shift+s exec ${scripts}/bin/ssh-menu
      bindsym $mod+v exec ${scripts}/bin/clipboard-menu

      # Lanceur — Meta seul ouvre wofi, comme KRunner sous KDE (Meta seul).
      # On utilise le keysym littéral (Super_L/Super_R) plutôt que $mod :
      # "bindsym --release $mod" est peu fiable pour détecter un appui seul.
      bindsym --release Super_L exec ${scripts}/bin/toggle-launcher
      bindsym --release Super_R exec ${scripts}/bin/toggle-launcher
      # Alt+F1 — équivalent du "activate application launcher" Plasma.
      bindsym Mod1+F1 exec ${scripts}/bin/toggle-launcher

      # Terminal / fermeture de fenêtre.
      bindsym $mod+Return exec ${terminal}
      bindsym Ctrl+Alt+t exec ${terminal}
      bindsym $mod+e exec dolphin
      bindsym Mod1+F4 kill

      # Navigation entre fenêtres — Alt+Tab / Alt+Shift+Tab, comme
      # "Walk Through Windows" sous KWin.
      bindsym Mod1+Tab exec ${scripts}/bin/alt-tab next
      bindsym Mod1+Shift+Tab exec ${scripts}/bin/alt-tab prev

      # Focus / déplacement de fenêtres — flèches uniquement (pas de hjkl).
      # "l" reste réservé au verrouillage (Meta+L comme sous KDE).
      bindsym $mod+Left  exec ${scripts}/bin/focus-warp left
      bindsym $mod+Down  exec ${scripts}/bin/focus-warp down
      bindsym $mod+Up    exec ${scripts}/bin/focus-warp up
      bindsym $mod+Right exec ${scripts}/bin/focus-warp right

      bindsym $mod+Shift+Left  move left
      bindsym $mod+Shift+Down  move down
      bindsym $mod+Shift+Up    move up
      bindsym $mod+Shift+Right move right

      # Verrouillage — Meta+L comme sous KDE.
      bindsym $mod+l exec ${lock}

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
        bindsym Left  resize shrink width 20px
        bindsym Down  resize grow height 20px
        bindsym Up    resize shrink height 20px
        bindsym Right resize grow width 20px
        bindsym Escape mode "default"
        bindsym Return mode "default"
      }

      # Workspaces — Meta+1/2/3 (parité avec les raccourcis "task manager
      # entry 1/2/3" de Plasma, mais ici ce sont des espaces de travail).
      bindsym $mod+1 workspace 1
      bindsym $mod+2 workspace 2
      bindsym $mod+3 workspace 3
      bindsym $mod+4 workspace 4
      bindsym $mod+5 workspace 5
      bindsym $mod+6 workspace 6
      bindsym $mod+7 workspace 7
      bindsym $mod+8 workspace 8
      bindsym $mod+9 workspace 9
      bindsym $mod+0 workspace 10
      bindsym $mod+Shift+1 move container to workspace 1
      bindsym $mod+Shift+2 move container to workspace 2
      bindsym $mod+Shift+3 move container to workspace 3
      bindsym $mod+Shift+4 move container to workspace 4
      bindsym $mod+Shift+5 move container to workspace 5
      bindsym $mod+Shift+6 move container to workspace 6
      bindsym $mod+Shift+7 move container to workspace 7
      bindsym $mod+Shift+8 move container to workspace 8
      bindsym $mod+Shift+9 move container to workspace 9
      bindsym $mod+Shift+0 move container to workspace 10

      # Capture d'écran — équivalent Spectacle (grim+slurp+swappy).
      bindsym Print exec ${scripts}/bin/screenshot-full
      bindsym $mod+Print exec ${scripts}/bin/screenshot-region
      bindsym Shift+Print exec ${scripts}/bin/screenshot-region

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

  # Presse-papiers "à la Win+V" : capture le contenu copié en tâche de fond ;
  # $mod+v ouvre le menu wofi qui lit cet historique.
  services.cliphist.enable = true;

  # Montage automatique des périphériques amovibles + icône de tray tant
  # qu'un périphérique est monté (équivalent du "device notifier" Plasma).
  # Nécessite services.udisks2.enable côté système
  # (modules/nixos/desktop/sway.nix).
  services.udiskie = {
    enable = true;
    tray = "auto";
  };
}
