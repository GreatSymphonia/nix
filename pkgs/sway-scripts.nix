{ pkgs }:

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

  screenshotRegion = pkgs.writeShellScriptBin "screenshot-region" ''
    ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.swappy}/bin/swappy -f -
  '';

  screenshotFull = pkgs.writeShellScriptBin "screenshot-full" ''
    ${pkgs.grim}/bin/grim - | ${pkgs.swappy}/bin/swappy -f -
  '';

  # Menu de session "à la KDE" : wofi dmenu avec verrouillage / suspension /
  # déconnexion / redémarrage / extinction.
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

  # Lanceur SSH : liste les hôtes de ~/.ssh/config (sans motif générique) et
  # ouvre un terminal connecté à l'hôte choisi.
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

  # Historique du presse-papiers "à la Win+V" : services.cliphist alimente
  # l'historique en tâche de fond, ce menu ne fait que le lire.
  clipboardMenu = pkgs.writeShellScriptBin "clipboard-menu" ''
    set -euo pipefail
    entry=$(${pkgs.cliphist}/bin/cliphist list | ${pkgs.wofi}/bin/wofi --dmenu --prompt "Presse-papiers" --width 500 --height 400)
    [ -n "$entry" ] && printf '%s' "$entry" | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy
  '';

  # Change le focus dans la direction donnée, puis place le curseur dans le
  # coin inférieur droit de la fenêtre nouvellement focus.
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

  # "focus next/prev" ne cycle que parmi les enfants du même conteneur. Ce
  # script construit la liste de toutes les fenêtres de l'arbre et fait un
  # vrai Alt+Tab global.
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

  # Icône batterie "à la KDE" : clic molette bascule l'inhibition de la mise
  # en veille automatique (verrouillage + dpms de swayidle), clic gauche
  # change de profil d'alimentation.
  #
  # L'inhibition passe par une fenêtre factice invisible taguée
  # app_id=idle-inhibitor-dummy, avec la règle `inhibit_idle open` dans la
  # config sway : c'est le seul mécanisme qui bloque réellement swayidle
  # (protocole idle-inhibit Wayland).
  idleInhibitDummyAppId = "idle-inhibitor-dummy";

  # Ghostty ignore l'option "class" : sous Wayland son app_id reste toujours
  # "com.mitchellh.ghostty". La fenêtre factice est donc repérée par son titre.
  toggleIdleInhibit = pkgs.writeShellScriptBin "toggle-idle-inhibit" ''
    set -euo pipefail
    title="${idleInhibitDummyAppId}"
    pid=$(${pkgs.sway}/bin/swaymsg -t get_tree \
      | ${pkgs.jq}/bin/jq -r --arg t "$title" \
          '[.. | objects | select(.name? == $t) | .pid] | first // empty')
    if [ -n "$pid" ]; then
      # `swaymsg kill` reste bloqué : Ghostty affiche une confirmation
      # invisible dans le scratchpad. On tue directement le process.
      kill -9 "$pid" 2>/dev/null || true
    else
      ${pkgs.ghostty}/bin/ghostty --title="$title" -e sleep infinity &
      disown
      # `for_window` s'évalue avant que Ghostty n'applique --title : on
      # attend que la fenêtre apparaisse, puis on applique inhibit_idle +
      # scratchpad nous-mêmes.
      for _ in $(seq 1 20); do
        if ${pkgs.sway}/bin/swaymsg -t get_tree \
            | ${pkgs.jq}/bin/jq -e --arg t "$title" \
                '.. | objects | select(.name? == $t)' >/dev/null; then
          ${pkgs.sway}/bin/swaymsg "[title=\"^$title\$\"] inhibit_idle open, move to scratchpad"
          break
        fi
        sleep 0.1
      done
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
        title="${idleInhibitDummyAppId}"
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
            | ${pkgs.jq}/bin/jq -e --arg t "$title" \
                '.. | objects | select(.name? == $t)' >/dev/null; then
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
in
pkgs.symlinkJoin {
  name = "sway-scripts";
  paths = [
    toggleLauncher
    screenshotRegion
    screenshotFull
    sessionMenu
    sshMenu
    clipboardMenu
    focusWarp
    altTab
    toggleIdleInhibit
    cyclePowerProfile
    batteryStatus
  ];
}
