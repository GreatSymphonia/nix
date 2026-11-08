{
  lib,
  fetchurl,
  appimageTools,
}:

# Port PC natif de Twilight Princess. Le build depuis le flake amont échoue
# (submodule extern/aurora incompatible avec le dawn épinglé), donc on
# installe l'AppImage officielle.
# https://github.com/TwilitRealm/dusklight/releases
let
  version = "1.4.1";

  appimage = fetchurl {
    url = "https://github.com/TwilitRealm/dusklight/releases/download/v${version}/Dusklight-v${version}-linux-x86_64.AppImage";
    hash = "sha256-9d0TCMExQwlFzBLN1E8i0x491uxUWEmEkZJKXp+pLUA=";
  };

  appimageContents = appimageTools.extractType2 {
    pname = "dusklight";
    inherit version;
    src = appimage;
  };
in
appimageTools.wrapType2 {
  pname = "dusklight";
  inherit version;
  src = appimage;

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/dev.twilitrealm.dusk.desktop \
      $out/share/applications/dev.twilitrealm.dusk.desktop
    install -Dm444 ${appimageContents}/dev.twilitrealm.dusk.png \
      $out/share/icons/hicolor/512x512/apps/dev.twilitrealm.dusk.png
  '';

  meta = {
    description = "Native PC port of Twilight Princess";
    homepage = "https://github.com/TwilitRealm/dusklight";
    platforms = [ "x86_64-linux" ];
    license = lib.licenses.unfree;
  };
}
