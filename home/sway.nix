{ pkgs, ... }:

let
  terminal = "${pkgs.ghostty}/bin/ghostty";
  lock = "${pkgs.swaylock}/bin/swaylock -f";
  # Bascule wofi : le ferme s'il est déjà ouvert plutôt que d'en relancer
  # une nouvelle instance à chaque appui.
  toggleLauncher = pkgs.writeShellScriptBin "toggle-launcher" ''
    # Le wrapper Nix renomme le process en ".wofi-wrapped" (visible dans
    # /proc/*/comm), pas "wofi" — pkill -x doit cibler ce nom-là.
    if ${pkgs.procps}/bin/pkill -x .wofi-wrapped; then
      exit 0
    fi
    exec ${pkgs.wofi}/bin/wofi --show drun
  '';
  menu = "${toggleLauncher}/bin/toggle-launcher";
  screenshotRegion = pkgs.writeShellScriptBin "screenshot-region" ''
    ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.swappy}/bin/swappy -f -
  '';
  screenshotFull = pkgs.writeShellScriptBin "screenshot-full" ''
    ${pkgs.grim}/bin/grim - | ${pkgs.swappy}/bin/swappy -f -
  '';
  # Menu de session "à la KDE" (Leave... de l'application launcher) : un
  # wofi dmenu avec verrouillage / suspension / déconnexion / redémarrage /
  # extinction. Le choix est fait par sélection explicite dans wofi, donc
  # pas de double confirmation nécessaire.
  sessionMenu = pkgs.writeShellScriptBin "session-menu" ''
    set -euo pipefail
    choice=$(printf '%s\n' \
      " Verrouiller" \
      " Suspendre" \
      " Déconnexion" \
      " Redémarrer" \
      " Éteindre" \
      | ${pkgs.wofi}/bin/wofi --dmenu --prompt "Session" --width 300 --height 250)
    case "$choice" in
      *Verrouiller*)  exec ${lock} ;;
      *Suspendre*)    exec ${pkgs.systemd}/bin/systemctl suspend ;;
      *Déconnexion*)  exec ${pkgs.sway}/bin/swaymsg exit ;;
      *Redémarrer*)   exec ${pkgs.systemd}/bin/systemctl reboot ;;
      *Éteindre*)     exec ${pkgs.systemd}/bin/systemctl poweroff ;;
    esac
  '';
  # Lanceur SSH "à la rofi" : liste les hôtes déclarés dans ~/.ssh/config
  # (entrées "Host" sans motif générique) et ouvre un terminal connecté à
  # l'hôte choisi, comme le ferait un lanceur d'applications pour une app.
  sshMenu = pkgs.writeShellScriptBin "ssh-menu" ''
    set -euo pipefail
    config="$HOME/.ssh/config"
    hosts=""
    if [ -r "$config" ]; then
      hosts=$(${pkgs.gawk}/bin/awk 'tolower($1) == "host" { for (i = 2; i <= NF; i++) print $i }' "$config" \
        | ${pkgs.gnugrep}/bin/grep -vE '[*?]' \
        | sort -u)
    fi
    if [ -z "$hosts" ]; then
      ${pkgs.libnotify}/bin/notify-send "SSH" "Aucun hôte trouvé dans ~/.ssh/config"
      exit 0
    fi
    host=$(printf '%s\n' "$hosts" | ${pkgs.wofi}/bin/wofi --dmenu --prompt "SSH" --width 300 --height 300)
    [ -n "$host" ] && exec ${terminal} -e ${pkgs.openssh}/bin/ssh "$host"
  '';
  # Change le focus dans la direction donnée, puis place le curseur dans le
  # coin inférieur droit (avec une marge) de la fenêtre nouvellement focus,
  # pour que la souris ne saute jamais au centre.
  focusWarp = pkgs.writeShellScriptBin "focus-warp" ''
    set -euo pipefail
    ${pkgs.sway}/bin/swaymsg focus "$1"
    read -r x y w h < <(
      ${pkgs.sway}/bin/swaymsg -t get_tree \
        | ${pkgs.jq}/bin/jq -r '.. | select(.focused? == true) | "\(.rect.x) \(.rect.y) \(.rect.width) \(.rect.height)"' \
        | head -n1
    )
    margin=25
    ${pkgs.sway}/bin/swaymsg seat seat0 cursor set "$((x + w - margin))" "$((y + h - margin))"
  '';
  # "focus next/prev" ne cycle que parmi les enfants du même conteneur : avec
  # un seul écran = un seul conteneur par sortie, il n'y a rien à parcourir.
  # Ce script construit la liste de toutes les fenêtres de l'arbre (tous
  # écrans/workspaces confondus) et fait un vrai Alt+Tab global.
  # Icône batterie "à la KDE" : clic molette bascule l'inhibition de la mise
  # en veille automatique (verrouillage + dpms de swayidle), clic gauche
  # change de profil d'alimentation (secondaire).
  #
  # L'inhibition passe par une fenêtre factice invisible taguée
  # app_id=idle-inhibitor-dummy, avec la règle `inhibit_idle open` dans la
  # config sway (voir extraConfig) : c'est le seul mécanisme qui bloque
  # réellement swayidle (protocole idle-inhibit Wayland), contrairement à
  # systemd-inhibit qui n'agit que sur logind.
  idleInhibitDummyAppId = "idle-inhibitor-dummy";
  toggleIdleInhibit = pkgs.writeShellScriptBin "toggle-idle-inhibit" ''
    set -euo pipefail
    app_id="${idleInhibitDummyAppId}"
    if ${pkgs.sway}/bin/swaymsg -t get_tree \
        | ${pkgs.jq}/bin/jq -e --arg a "$app_id" \
            '.. | objects | select(.app_id? == $a)' >/dev/null; then
      ${pkgs.sway}/bin/swaymsg "[app_id=\"$app_id\"] kill"
    else
      ${pkgs.ghostty}/bin/ghostty --class="$app_id" --title="$app_id" -e sleep infinity &
      disown
    fi
    ${pkgs.procps}/bin/pkill -RTMIN+8 waybar || true
  '';
  cyclePowerProfile = pkgs.writeShellScriptBin "cycle-power-profile" ''
    set -euo pipefail
    ppc=${pkgs.power-profiles-daemon}/bin/powerprofilesctl
    current=$("$ppc" get 2>/dev/null || echo balanced)
    case "$current" in
      performance) next=power-saver ;;
      power-saver) next=balanced ;;
      *) next=performance ;;
    esac
    "$ppc" set "$next" 2>/dev/null || true
    ${pkgs.procps}/bin/pkill -RTMIN+8 waybar || true
  '';
  batteryStatus = pkgs.writeShellScriptBin "battery-status" ''
    set -euo pipefail
    app_id="${idleInhibitDummyAppId}"
    bat_dir=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1 || true)
    if [ -n "$bat_dir" ]; then
      capacity=$(cat "$bat_dir/capacity" 2>/dev/null || echo 0)
      status=$(cat "$bat_dir/status" 2>/dev/null || echo Unknown)
    else
      capacity=100
      status=Unknown
    fi

    icons=($'' $'' $'' $'' $'')
    idx=$(( capacity * 5 / 101 ))
    [ "$idx" -gt 4 ] && idx=4
    icon="''${icons[$idx]}"
    [ "$status" = "Charging" ] && icon=$' '"$icon"

    if ${pkgs.sway}/bin/swaymsg -t get_tree \
        | ${pkgs.jq}/bin/jq -e --arg a "$app_id" \
            '.. | objects | select(.app_id? == $a)' >/dev/null; then
      inhibited=true
      icon="$icon "
    else
      inhibited=false
    fi

    profile=$(${pkgs.power-profiles-daemon}/bin/powerprofilesctl get 2>/dev/null || echo "")

    tooltip="''${capacity}% (''${status})"
    [ -n "$profile" ] && tooltip="''${tooltip}
Profil : ''${profile} (clic gauche pour changer)"
    if [ "$inhibited" = true ]; then
      tooltip="''${tooltip}
Veille automatique désactivée (clic molette pour réactiver)"
      class=inhibited
    else
      tooltip="''${tooltip}
Clic molette : désactiver la veille/le verrouillage automatique"
      class=$(echo "$status" | ${pkgs.coreutils}/bin/tr '[:upper:] ' '[:lower:]-')
    fi

    ${pkgs.jq}/bin/jq -nc --arg text "$icon" --arg tooltip "$tooltip" \
      --arg class "$class" --argjson percentage "$capacity" \
      '{text: $text, tooltip: $tooltip, class: $class, percentage: $percentage}'
  '';
  altTab = pkgs.writeShellScriptBin "alt-tab" ''
    set -euo pipefail
    dir="''${1:-next}"
    tree=$(${pkgs.sway}/bin/swaymsg -t get_tree)
    ids=$(echo "$tree" | ${pkgs.jq}/bin/jq -c '[.. | objects | select(.pid != null) | .id]')
    current=$(echo "$tree" | ${pkgs.jq}/bin/jq '.. | objects | select(.focused? == true) | .id')
    target=$(echo "$ids" | ${pkgs.jq}/bin/jq --argjson cur "$current" --arg dir "$dir" '
      . as $a
      | ($a | index($cur)) as $i
      | if ($a | length) == 0 then empty
        elif $i == null then $a[0]
        elif $dir == "prev" then $a[($i - 1 + ($a|length)) % ($a|length)]
        else $a[($i + 1) % ($a|length)]
        end
    ')
    [ -n "$target" ] && ${pkgs.sway}/bin/swaymsg "[con_id=$target] focus"
    exit 0
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
    jq
    networkmanagerapplet
    pasystray
    kdePackages.polkit-kde-agent-1
    screenshotRegion
    screenshotFull
    focusWarp
    altTab
    toggleLauncher
    toggleIdleInhibit
    cyclePowerProfile
    batteryStatus
    power-profiles-daemon
    sessionMenu
    sshMenu
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

      # Fenêtre factice utilisée par l'icône batterie de waybar (clic
      # molette) pour inhiber la veille automatique : `inhibit_idle open`
      # bloque swayidle tant que la fenêtre existe, qu'elle soit visible ou
      # non ; on la pousse donc dans le scratchpad pour qu'elle ne s'affiche
      # jamais.
      for_window [app_id="^${idleInhibitDummyAppId}$"] {
        inhibit_idle open
        move to scratchpad
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
        output "DP-9"
      }

      # --- Démarrage automatique ---------------------------------------------
      exec ${pkgs.mako}/bin/mako
      exec ${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1
      # Trousseau KDE (org.freedesktop.secrets) — sous Plasma, kwalletd est
      # démarré par le login PAM (auto-déverrouillé), mais ce mécanisme ne
      # s'accroche pas correctement à la session sway : le process reste
      # bloqué sans jamais s'enregistrer sur le bus D-Bus. On le relance
      # explicitement ici ; il réutilise le même portefeuille
      # (~/.config/kwalletrc, ~/.local/share/kwalletd/kdewallet.kwl) et
      # demandera le mot de passe au premier accès (Claude, etc.).
      exec ${pkgs.kdePackages.kwallet}/bin/kwalletd6
      # Icônes de tray avec menus interactifs (équivalent des applets Plasma
      # réseau / audio) : cliquer donne un vrai menu (réseaux Wi-Fi,
      # sorties audio, volume), pas juste du texte dans la barre.
      exec ${pkgs.networkmanagerapplet}/bin/nm-applet --indicator
      exec ${pkgs.pasystray}/bin/pasystray

      # ======================= Raccourcis (calqués sur KDE) ===================

      # Menu de session (verrouiller/suspendre/déconnexion/redémarrer/
      # éteindre) — Ctrl+Alt+Del comme le "Leave..." de KDE.
      bindsym Ctrl+Alt+Delete exec ${sessionMenu}/bin/session-menu

      # Lanceur SSH — liste les hôtes de ~/.ssh/config dans wofi.
      bindsym $mod+Shift+s exec ${sshMenu}/bin/ssh-menu

      # Lanceur — Meta seul ouvre wofi, comme KRunner sous KDE (Meta seul).
      # On utilise le keysym littéral (Super_L/Super_R) plutôt que $mod :
      # "bindsym --release $mod" (l'alias de modificateur) est peu fiable
      # pour détecter un appui seul, contrairement au keysym direct.
      bindsym --release Super_L exec ${menu}
      bindsym --release Super_R exec ${menu}
      # Alt+F1 — équivalent du "activate application launcher" Plasma.
      bindsym Mod1+F1 exec ${menu}

      # Terminal / fermeture de fenêtre.
      bindsym $mod+Return exec ${terminal}
      bindsym Ctrl+Alt+t exec ${terminal}
      bindsym $mod+e exec dolphin
      bindsym Mod1+F4 kill

      # Navigation entre fenêtres — Alt+Tab / Alt+Shift+Tab, comme
      # "Walk Through Windows" sous KWin. "focus next/prev" natif de sway ne
      # cycle que parmi les enfants du même conteneur (rien à faire s'il n'y
      # a qu'une fenêtre par écran) : alt-tab construit une liste de toutes
      # les fenêtres, tous écrans confondus.
      bindsym Mod1+Tab exec ${altTab}/bin/alt-tab next
      bindsym Mod1+Shift+Tab exec ${altTab}/bin/alt-tab prev

      # Focus / déplacement de fenêtres — flèches uniquement (pas de hjkl).
      # "l" reste réservé au verrouillage (Meta+L comme sous KDE).
      # Le focus passe par focus-warp : après le changement de focus, la
      # souris est replacée dans le coin inférieur droit de la fenêtre
      # focus (à ~25px des bords) plutôt qu'au centre.
      bindsym $mod+Left  exec ${focusWarp}/bin/focus-warp left
      bindsym $mod+Down  exec ${focusWarp}/bin/focus-warp down
      bindsym $mod+Up    exec ${focusWarp}/bin/focus-warp up
      bindsym $mod+Right exec ${focusWarp}/bin/focus-warp right

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
      output = [ "DP-9" ];
      modules-left = [ "sway/workspaces" "sway/mode" ];
      modules-center = [ "clock" ];
      # Audio et réseau ne sont plus des modules texte waybar : nm-applet et
      # pasystray (démarrés via exec) apparaissent dans le tray avec un
      # vrai menu interactif au clic (réseaux Wi-Fi, sorties audio), comme
      # les applets Plasma. Les modules restants sont réduits à l'icône.
      modules-right = [
        "backlight"
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
      # profil d'alimentation (secondaire). Voir toggleIdleInhibit /
      # cyclePowerProfile / batteryStatus dans extraConfig ci-dessus.
      "custom/battery" = {
        exec = "${batteryStatus}/bin/battery-status";
        return-type = "json";
        interval = 15;
        signal = 8;
        on-click = "${cyclePowerProfile}/bin/cycle-power-profile";
        on-click-middle = "${toggleIdleInhibit}/bin/toggle-idle-inhibit";
      };
      backlight = {
        format = "{icon}";
        format-icons = [ "" "" "" "" "" ];
        tooltip-format = "{percent}%";
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
      #backlight,
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
