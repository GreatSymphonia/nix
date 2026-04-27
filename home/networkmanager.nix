{ pkgs, lib, ... }:

let
  nmcli = "${pkgs.networkmanager}/bin/nmcli";
  mkdir = "${pkgs.coreutils}/bin/mkdir";
  install = "${pkgs.coreutils}/bin/install";
  grep = "${pkgs.gnugrep}/bin/grep";
  basename = "${pkgs.coreutils}/bin/basename";
  profileDir = "/home/louis/.netconfig/networkmanager";

  ensureProfile = source: staged: connectionName: connectionType: ''
    ensure_profile() {
      local source_path="$1"
      local staged_path="$2"
      local connection_name="$3"
      local connection_type="$4"
      local imported_name

      if [ ! -f "$source_path" ]; then
        return 0
      fi

      ${mkdir} -p -m 700 "${profileDir}"
      ${install} -m 600 "$source_path" "$staged_path"

      if ! ${nmcli} general status >/dev/null 2>&1; then
        return 0
      fi

      if ${nmcli} -t -f NAME connection show 2>/dev/null | ${grep} -Fxq "$connection_name"; then
        return 0
      fi

      ${nmcli} connection import type "$connection_type" file "$staged_path" >/dev/null 2>&1 || true

      imported_name="$(${basename} "$staged_path")"
      imported_name="''${imported_name%.*}"

      if ${nmcli} -t -f NAME connection show 2>/dev/null | ${grep} -Fxq "$imported_name"; then
        ${nmcli} connection modify "$imported_name" connection.id "$connection_name" >/dev/null 2>&1 || true
      fi
    }

    ensure_profile "${source}" "${staged}" "${connectionName}" "${connectionType}"
  '';
in {
  home.activation.importNetworkManagerProfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    ensureProfile
      "/home/louis/Downloads/Sysadmin-LanETS.ovpn"
      "${profileDir}/Sysadmin-LanETS.ovpn"
      "Sysadmin-LanETS"
      "openvpn"
    + ensureProfile
      "/home/louis/Downloads/louis.conf"
      "${profileDir}/louis.conf"
      "louis"
      "wireguard"
  );
}