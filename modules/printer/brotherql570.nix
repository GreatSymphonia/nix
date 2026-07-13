{ stdenv
, gcc
, cups
}:

stdenv.mkDerivation rec {
  pname = "brother-ql570";
  version = "1.0.1";

  src = ./.;

  buildInputs = [
    gcc
    cups
  ];

  buildPhase = ''
    pushd cupswrapper-ql570-src-1.1.1-1/brcupsconfig
    gcc -O2 -Wall -o brcupsconfpt1 brcupsconfig.c
    popd
  '';

  installPhase = ''
    mkdir -p $out

    #
    # installation du driver Brother
    #
    mkdir -p $out/opt/brother/PTouch/ql570

    cp -r \
      ql570lpr-1.0.1-0.i386/opt/brother/PTouch/ql570/* \
      $out/opt/brother/PTouch/ql570/

    #
    # remplace le binaire fourni
    #
    install -Dm755 \
      cupswrapper-ql570-src-1.1.1-1/brcupsconfig/brcupsconfpt1 \
      $out/opt/brother/PTouch/ql570/cupswrapper/brcupsconfpt1

    #
    # patch du filtre principal
    #
    substituteInPlace \
      $out/opt/brother/PTouch/ql570/lpd/filterql570 \
      --replace "/opt/brother" "$out/opt/brother"

    #
    # ppd
    #
    install -Dm644 \
      cupswrapper-ql570-src-1.1.1-1/ppd/brother_ql570_printer_en.ppd \
      $out/share/cups/model/brother_ql570_printer_en.ppd

    #
    # filtre cups
    #
    mkdir -p $out/lib/cups/filter

    cat > $out/lib/cups/filter/brother_lpdwrapper_ql570 <<EOF
#!${stdenv.shell}

export BROTHER_PREFIX="$out"

exec $out/opt/brother/PTouch/ql570/lpd/filterql570 "\$@"
EOF

    chmod +x \
      $out/lib/cups/filter/brother_lpdwrapper_ql570
  '';
}
