{ pkgs, ... }:

let
  # Pas dans systemPackages : le binaire s'appelle aussi "sway" et
  # entrerait en collision avec celui de programs.sway (vanilla).
  swayfx = pkgs.swayfx.override { withGtkWrapper = true; };

  launcher = pkgs.writeShellScript "swayfx-session" ''
    export XDG_SESSION_TYPE=wayland
    export XDG_CURRENT_DESKTOP=sway

    # Thème Qt/KDE (Dolphin, Kate, etc.) et couleurs complètes de Plasma
    export QT_QPA_PLATFORMTHEME=kde
    export XDG_CONFIG_DIRS="$HOME/.config/kdedefaults''${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}"


    cfg="$HOME/.config/swayfx/config"
    if [ -r "$cfg" ]; then
      exec ${swayfx}/bin/sway --config "$cfg" "$@"
    fi
    # Repli si le home-manager n'a pas encore été appliqué : config sway classique.
    exec ${swayfx}/bin/sway "$@"
  '';

  sessionPackage = (pkgs.writeTextFile {
    name = "swayfx-session";
    destination = "/share/wayland-sessions/swayfx.desktop";
    text = ''
      [Desktop Entry]
      Name=SwayFX
      Comment=Sway avec effets visuels (SwayFX)
      Exec=${launcher}
      Type=Application
      DesktopNames=sway
    '';
  }) // {
    providedSessions = [ "swayfx" ];   # doit correspondre au nom du .desktop
  };
in
{
  services.displayManager.sessionPackages = [ sessionPackage ];
}
