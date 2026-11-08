{
  lib,
  stdenvNoCC,
  fetchurl,
}:

# nixpkgs-unstable traîne derrière l'instance Omni (cedille), qui exige un
# client plus récent. On épingle le binaire statique officiel de siderolabs.
# Vérifier les mises à jour avec `omnictl-check-update` (home/shell.nix).
let
  version = "1.12.1";
in
stdenvNoCC.mkDerivation {
  pname = "omnictl";
  inherit version;

  src = fetchurl {
    url = "https://github.com/siderolabs/omni/releases/download/v${version}/omnictl-linux-amd64";
    hash = "sha256-/ZfeF5geRETvruriPMqMVSC803pZjjgiev6DUDjvaGA=";
  };

  dontUnpack = true;

  installPhase = ''
    install -Dm755 $src $out/bin/omnictl
  '';

  meta = {
    description = "CLI client for Sidero Omni";
    homepage = "https://github.com/siderolabs/omni";
    platforms = [ "x86_64-linux" ];
  };
}
