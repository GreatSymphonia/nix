{ inputs }:
final: prev:
let
  system = final.stdenv.hostPlatform.system;

  unstable = import inputs.nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };
in
{
  inherit unstable;

  zen-browser = inputs.zen-browser.packages.${system}.default;

  brother-ql570 = final.callPackage ./brother-ql570 {
    brotherQl570Sources = {
      cupswrapper = inputs.brother-ql570-src + "/cupswrapper-ql570-src-1.1.1-1";
      lpr = inputs.brother-ql570-src + "/ql570lpr-1.0.1-0.i386";
    };
  };

  # libServiceCore.so utilise zlibVersion mais n'a pas d'entrée DT_NEEDED pour
  # libz.so.1, ce qui provoque "undefined symbol: zlibVersion" au démarrage.
  # On ajoute la dépendance manquante avant autoPatchelfHook.
  muse-sounds-manager = prev.muse-sounds-manager.overrideAttrs (old: {
    preFixup = (old.preFixup or "") + ''
      patchelf --add-needed libz.so.1 $out/bin/libServiceCore.so
    '';
  });

  omnictl = final.callPackage ./omnictl.nix { };
  sway-scripts = import ./sway-scripts.nix { pkgs = final; };
  dusklight = final.callPackage ./dusklight.nix { };
  pandoc-xelatex = final.callPackage ./pandoc-xelatex.nix { };
}
