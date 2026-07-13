# pkgs/brother-ql570/default.nix

{ stdenv
, cups
, gcc
}:

stdenv.mkDerivation {
  pname = "brother-ql570";
  version = "1.0.1";

  src = ./.;

  nativeBuildInputs = [
    gcc
  ];

  buildPhase = ''
    gcc \
      -O2 \
      -Wall \
      -o brcupsconfpt1 \
      cupswrapper-ql570-src-1.1.1-1/brcupsconfig/brcupsconfig.c
  '';

  installPhase = ''
    mkdir -p $out

    cp -r \
      ql570lpr-1.0.1-0.i386/opt \
      $out/

    mkdir -p \
      $out/opt/brother/PTouch/ql570/cupswrapper

    install -Dm755 \
      brcupsconfpt1 \
      $out/opt/brother/PTouch/ql570/cupswrapper/brcupsconfpt1

    substituteInPlace \
      $out/opt/brother/PTouch/ql570/lpd/filterql570 \
      --replace "/opt/brother" "$out/opt/brother"

    substituteInPlace \
      $out/opt/brother/PTouch/ql570/lpd/psconvertpt1 \
      --replace "/opt/brother" "$out/opt/brother"

    mkdir -p \
      $out/share/cups/model

    install -Dm644 \
      cupswrapper-ql570-src-1.1.1-1/ppd/brother_ql570_printer_en.ppd \
      $out/share/cups/model/brother_ql570_printer_en.ppd

    mkdir -p \
      $out/lib/cups/filter
  '';
}
