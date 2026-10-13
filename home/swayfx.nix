{ config, lib, pkgs, ... }:

let
  swaycfg = config.wayland.windowManager.sway;
  waybarPkg = config.programs.waybar.package;
  asText = v: if v == null then "" else if lib.isString v then v else builtins.readFile v;

  # --- Waybar dédié à SwayFX ------------------------------------------------
  waybarFxConfig = pkgs.writeText "waybar-swayfx.json" (builtins.toJSON [
    (config.programs.waybar.settings.mainBar // {
      margin = "6 8 0 8";   # barre flottante
    })
  ]);

  waybarFxStyle = pkgs.writeText "waybar-swayfx.css" ''
    ${asText config.programs.waybar.style}

    window#waybar {
      background-color: alpha(@base, 0.65);
      border: 1px solid alpha(@surface2, 0.6);
      border-radius: 12px;
    }
    #custom-battery,
    #custom-notification,
    #tray,
    #clock {
      background-color: alpha(@surface0, 0.6);
      border-radius: 8px;
    }
  '';

  # Superviseur : relance waybar s'il meurt (pause de 2 s), sans toucher à sway,
  # et journalise sa sortie dans $XDG_RUNTIME_DIR/waybar-swayfx.log.
  waybarFx = pkgs.writeShellScript "waybar-swayfx" ''
    log="''${XDG_RUNTIME_DIR:-/tmp}/waybar-swayfx.log"
    child=""
    trap 'if [ -n "$child" ]; then kill "$child" 2>/dev/null; fi; exit 0' TERM INT
    while true; do
      ${waybarPkg}/bin/waybar -c ${waybarFxConfig} -s ${waybarFxStyle} "$@" >>"$log" 2>&1 &
      child=$!
      wait "$child" || true
      sleep 2
    done
  '';

  # --- Menu scratchpad -------------------------------------------------------
  scratchpadMenu = pkgs.writeShellScriptBin "scratchpad-menu" ''
    set -euo pipefail
    dummy="idle-inhibitor-dummy"
    entries=$(${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -r --arg d "$dummy" '
      .. | objects | select(.type? == "workspace" and .name == "__i3_scratch")
      | .floating_nodes[]?
      | select(.name != $d)
      | "\(.id)  \(.app_id // .window_properties.class // "?") — \(.name)"')
    if [ -z "$entries" ]; then
      ${pkgs.libnotify}/bin/notify-send "Scratchpad" "Aucune fenêtre cachée"
      exit 0
    fi
    choice=$(printf '%s\n' "$entries" | ${pkgs.wofi}/bin/wofi --dmenu --prompt "Scratchpad" --width 600 --height 300)
    [ -n "$choice" ] || exit 0
    id=$(printf '%s' "$choice" | ${pkgs.gawk}/bin/awk '{print $1}')
    ${pkgs.sway}/bin/swaymsg "[con_id=$id] scratchpad show"
  '';

  # --- Profils d'écrans (kanshi) --------------------------------------------
  # kanshi ne gère ici que eDP-1 (on/off) et les positions ; les modes
  # (1920x1080@75/100 Hz) viennent de tes lignes `output` statiques.
  kanshiConf = pkgs.writeText "kanshi-swayfx" ''
    profile docked {
      output "eDP-1" disable
      output "DP-11" enable position 0,0
      output "DP-9"  enable position 1920,0
      output "DP-10" enable position 3840,0
    }

    profile undocked {
      output "eDP-1" enable scale 1.5
    }
  '';

  # --- Ta config sway actuelle, adaptée pour la session SwayFX --------------
  dropLine = pattern: text:
    lib.concatStringsSep "\n"
      (builtins.filter (l: builtins.match pattern l == null) (lib.splitString "\n" text));

  base =
    dropLine "[[:space:]]*output \"eDP-1\" disable[[:space:]]*"
      (builtins.replaceStrings
        [ "swaybar_command waybar" ]
        [ "swaybar_command ${waybarFx}" ]
        swaycfg.extraConfig);

  fxExtra = ''

    # ======================= SwayFX (session dédiée) =========================

    # Intégration systemd (équivalent de ce que home-manager ajoute à la config
    # sway vanilla) + marqueur de session, lu par la condition du watchdog.
    exec "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP XDG_SESSION_TYPE SWAYFX_SESSION=1; ${pkgs.systemd}/bin/systemctl --user start sway-session.target"

    # Bascule automatique 1 ↔ 3 écrans (dock branché / débranché).
    exec ${pkgs.kanshi}/bin/kanshi -c ${kanshiConf}

    corner_radius 10
    gaps inner 6
    gaps outer 2

    blur enable
    blur_xray disable
    blur_passes 3
    blur_radius 5
    blur_noise 0.02
    blur_brightness 1.0
    blur_contrast 1.0
    blur_saturation 1.1

    shadows enable
    shadows_on_csd disable
    shadow_blur_radius 20
    shadow_offset 0 4
    shadow_color #00000080
    shadow_inactive_color #00000040

    default_dim_inactive 0.12
    dim_inactive_colors.unfocused #000000FF
    dim_inactive_colors.urgent    #900000FF
    # for_window [app_id="mpv"] dim_inactive 0.0

    layer_effects "waybar" {
      blur enable;
      blur_ignore_transparent enable;
      shadows enable;
      corner_radius 12;
    }
    layer_effects "launcher" {
      blur enable;
      blur_ignore_transparent enable;
      shadows enable;
      corner_radius 12;
    }
    layer_effects "swaync-notification-window" {
      blur enable;
      blur_ignore_transparent enable;
    }
    layer_effects "swaync-control-center" {
      blur enable;
      blur_ignore_transparent enable;
      shadows enable;
    }

    for_window [app_id="pavucontrol"]          floating enable
    for_window [app_id="nm-connection-editor"] floating enable

    bindsym $mod+Ctrl+Next exec ${scratchpadMenu}/bin/scratchpad-menu

    # scratchpad_minimize enable
    # animation_duration_ms 200
  '';
in
{
  xdg.configFile."swayfx/config".text = base + fxExtra;

  # Sans effet hors session SwayFX (la variable n'y existe pas) : dans SwayFX,
  # c'est le superviseur ci-dessus qui relance waybar, sans `swaymsg reload`.
  systemd.user.services.waybar-watchdog.Unit.ConditionEnvironment = "!SWAYFX_SESSION";
    dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
}
