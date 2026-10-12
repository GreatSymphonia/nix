{ config, lib, pkgs, ... }:

let
  swaycfg = config.wayland.windowManager.sway;
  asText = v: if v == null then "" else if lib.isString v then v else builtins.readFile v;

  # --- Waybar dédié à SwayFX (dérivé de ta config, sans la modifier) ---------
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

  # --- Menu scratchpad (liste les fenêtres cachées, ignore le dummy idle) ----
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

  # --- Ta config sway actuelle, lue telle quelle, avec waybar remplacé -------
  base = builtins.replaceStrings
    [ "swaybar_command waybar" ]
    [ "swaybar_command ${config.programs.waybar.package}/bin/waybar -c ${waybarFxConfig} -s ${waybarFxStyle}" ]
    swaycfg.extraConfig;

  fxExtra = ''

    # ======================= SwayFX (session dédiée) =========================

    # Équivalent de l'intégration systemd que home-manager ajoute à ~/.config/sway/config :
    # sans ça, sway-session.target ne démarre pas (swayidle, swaync, cliphist,
    # udiskie, waybar-watchdog en dépendent).
    exec "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP XDG_SESSION_TYPE; ${pkgs.systemd}/bin/systemctl --user start sway-session.target"

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

    # Namespaces : swaymsg -r -t get_outputs | jq '.[0].layer_shell_surfaces | .[] | .namespace'
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
}
