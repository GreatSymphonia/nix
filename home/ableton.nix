# ableton.nix
#
# Home Manager module to run Ableton Live under Wine on NixOS.
# Inspired by: https://github.com/korewaChino/live-on-linux
#
# IMPORTANT: this does NOT install Ableton itself. Nix can't package
# proprietary Windows installers reproducibly, so the actual install stays
# a one-time imperative step inside a Wine prefix, same as on any other
# distro. What THIS file gives you declaratively is everything around
# that: wine + winetricks, a launcher wrapper equivalent to upstream's
# `abletonlive` script, and the desktop entry / MIME + URI handler
# (so .als files and `ableton://` license-activation links work).
#
# --- One-time manual setup, after `home-manager switch` ---
#
#   1. Initialize the (dedicated) prefix:
#        WINEPREFIX=~/.wineableton wineboot
#
#   2. Install the VC++ runtimes Ableton needs:
#        WINEPREFIX=~/.wineableton winetricks vcrun2015 vcrun2017
#
#   3. Unzip your installer and run it inside that same prefix:
#        cd ~/Downloads && unzip ableton/_live_standard_12.4.6_64.zip -d ableton-installer
#        WINEPREFIX=~/.wineableton wine ableton-installer/*.exe
#
#      Check what path the installer actually writes to (Wine's file
#      manager or `find ~/.wineableton -iname '*.exe'` will show you) —
#      if it doesn't match `abletonExe` below, adjust `edition`/`liveVersion`
#      or set the path directly.
#
#   4. Launch via the app menu, `abletonlive` in a terminal, or by
#      opening an .als file.
#
# Note on Max for Live: if it crashes on first run, delete
#   ~/.wineableton/drive_c/users/$USER/AppData/Roaming/Cycling '74/Max 8/Settings/maxpreferences.maxpref
# and relaunch.
#
# Note on WineASIO (low-latency audio via JACK/PipeWire): it isn't in
# nixpkgs as of writing, so it's left out here. If you want it later
# you'd need to build github.com/wineasio/wineasio yourself (or find a
# community overlay/flake) and `wineasio-register` it into this prefix.
#
# Note on nixpkgs attribute names: this uses `wineWow64Packages`, the
# current (2026) name for the multi-arch wine set. If your channel is
# old enough to still call it `wineWowPackages`, swap that in instead.

{ config, lib, pkgs, ... }:

let
  wine = pkgs.wineWow64Packages.staging; # 32+64-bit, wine-staging branch
  winePrefix = "${config.home.homeDirectory}/.wineableton";

  # Must match what the installer actually created under drive_c.
  liveVersion = "12";
  edition = "Standard"; # "Standard" / "Suite" / "Lite"

  abletonExe =
    "${winePrefix}/drive_c/ProgramData/Ableton/Live ${liveVersion} ${edition}/Program/Ableton Live ${liveVersion} ${edition}.exe";

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
      echo "Run the installer inside $WINEPREFIX first (see comments in ableton.nix)." >&2
      exit 1
    fi

    if [ "$#" -eq 0 ]; then
      exec ${wine}/bin/wine64 "$exec_path"
    fi

    case "$1" in
      ableton://*)
        exec ${wine}/bin/wine64 "$exec_path" "$1"
        ;;
      *)
        abs_path=$(realpath "$1")
        exec ${wine}/bin/wine64 "$exec_path" "Z:$abs_path"
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
    categories = [ "AudioVideo" "Audio" ];
    mimeType = [ "x-scheme-handler/ableton" ]
      ++ map (ext: "application/x-wine-extension-${ext}") wineExtensions;
    settings = {
      StartupNotify = "true";
      StartupWMClass = "ableton live ${lib.toLower liveVersion} ${lib.toLower edition}.exe";
    };
  };

  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications =
    { "x-scheme-handler/ableton" = "abletonlive.desktop"; }
    // lib.listToAttrs (map
      (ext: lib.nameValuePair "application/x-wine-extension-${ext}" "abletonlive.desktop")
      wineExtensions);
}
