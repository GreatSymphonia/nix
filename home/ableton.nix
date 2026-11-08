# Ableton Live sous Wine. L'installation manuelle et les notes sont dans
# docs/ableton.md.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  wine = pkgs.wineWow64Packages.staging; # 32+64-bit, wine-staging branch
  winePrefix = "${config.home.homeDirectory}/.wineableton";

  # Must match what the installer actually created under drive_c.
  liveVersion = "12";
  edition = "Standard"; # "Standard" / "Suite" / "Lite"

  abletonExe = "${winePrefix}/drive_c/ProgramData/Ableton/Live ${liveVersion} ${edition}/Program/Ableton Live ${liveVersion} ${edition}.exe";

  wineExtensions = [
    "als"
    "abl"
    "adg"
    "adv"
    "alc"
    "alp"
    "auz"
    "amxd"
    "ablbundle"
  ];

  abletonlive = pkgs.writeShellScriptBin "abletonlive" ''
    set -euo pipefail

    export WINEPREFIX="${winePrefix}"
    exec_path="${abletonExe}"

    if [ ! -f "$exec_path" ]; then
      echo "Ableton executable not found at: $exec_path" >&2
      echo "Installer Ableton dans $WINEPREFIX d'abord (voir docs/ableton.md)." >&2
      exit 1
    fi

    if [ "$#" -eq 0 ]; then
      exec ${wine}/bin/wine "$exec_path"
    fi

    case "$1" in
      ableton://*)
        exec ${wine}/bin/wine "$exec_path" "$1"
        ;;
      *)
        abs_path=$(${pkgs.coreutils}/bin/realpath "$1")
        exec ${wine}/bin/wine "$exec_path" "Z:$abs_path"
        ;;
    esac
  '';
in
{
  home.packages = [
    abletonlive
    wine
    pkgs.winetricks
  ];

  xdg.desktopEntries.abletonlive = {
    name = "Ableton Live ${liveVersion} ${edition}";
    exec = "abletonlive %U";
    icon = "abletonlive"; # placeholder; extract a real .ico with icoutils if you want one
    type = "Application";
    terminal = false;
    categories = [
      "AudioVideo"
      "Audio"
    ];
    mimeType = [
      "x-scheme-handler/ableton"
    ]
    ++ map (ext: "application/x-wine-extension-${ext}") wineExtensions;
    settings = {
      StartupNotify = "true";
      StartupWMClass = "ableton live ${lib.toLower liveVersion} ${lib.toLower edition}.exe";
    };
  };

  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/ableton" = "abletonlive.desktop";
  }
  // lib.listToAttrs (
    map (
      ext: lib.nameValuePair "application/x-wine-extension-${ext}" "abletonlive.desktop"
    ) wineExtensions
  );
}
