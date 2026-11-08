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

  omnictl = final.callPackage ./omnictl.nix { };
  sway-scripts = import ./sway-scripts.nix { pkgs = final; };
  dusklight = final.callPackage ./dusklight.nix { };
  pandoc-xelatex = final.callPackage ./pandoc-xelatex.nix { };
}
