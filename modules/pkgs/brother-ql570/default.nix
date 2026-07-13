{ lib
, stdenv
, gcc
, cups
}:

stdenv.mkDerivation rec {
  pname = "brother-ql570";
  version = "1.0.1";

  src = builtins.path {
    path = ./.;
    name = "brother-ql570";
  };
  
  dontConfigure = true;

  nativeBuildInputs = [
    gcc
  ];

  buildPhase = ''
  echo "===== DEBUG ====="
  pwd
  find . -maxdepth 4 | sort
  echo "================="

  gcc \
      -O2 \
      -Wall \
      -o brcupsconfpt1 \
      ./cupswrapper-ql570-src-1.1.1-1/brcupsconfig/brcupsconfig.c
  '';

  installPhase = ''
    mkdir -p $out

    #
    # Fichiers du pilote LPR
    #
    cp -r \
      ql570lpr-1.0.1-0.i386/opt \
      $out/

    #
    # cupswrapper
    #
    mkdir -p \
      $out/opt/brother/PTouch/ql570/cupswrapper

    install -Dm755 \
      cupswrapper-ql570-src-1.1.1-1/brcupsconfig/brcupsconfpt1 \
      $out/opt/brother/PTouch/ql570/cupswrapper/brcupsconfpt1

    #
    # Patch des chemins Brother
    #
    substituteInPlace \
      $out/opt/brother/PTouch/ql570/lpd/filterql570 \
      --replace "/opt/brother" "$out/opt/brother"

    #
    # PPD
    #
    install -Dm644 \
      cupswrapper-ql570-src-1.1.1-1/ppd/brother_ql570_printer_en.ppd \
      $out/share/cups/model/brother_ql570_printer_en.ppd

    #
    # Filtre CUPS
    #
    mkdir -p \
      $out/lib/cups/filter

    cat > $out/lib/cups/filter/brother_lpdwrapper_ql570 <<EOF
#!${stdenv.shell}

PPDC=\$(printenv | sed -n 's/^PPD=//p')

if [ -z "\$PPDC" ]; then
  PPDC="$out/share/cups/model/brother_ql570_printer_en.ppd"
fi

RCFILE="/tmp/brql570rc_\$$"

cp \
  "$out/opt/brother/PTouch/ql570/inf/brql570rc" \
  "\$RCFILE"

chmod 600 "\$RCFILE"

export BRPRINTERRCFILE="\$RCFILE"

INPUT_PS=\$(mktemp)

if [ \$# -ge 7 ]; then
  cp "\$6" "\$INPUT_PS"
else
  cat > "\$INPUT_PS"
fi

"$out/opt/brother/PTouch/ql570/cupswrapper/brcupsconfpt1" \
  ql570 \
  "\$PPDC" \
  0 \
  "\$5 Copies=\$4" \
  "\$BRPRINTERRCFILE" \
  >/dev/null

cat "\$INPUT_PS" | \
  "$out/opt/brother/PTouch/ql570/lpd/filterql570" \
  "\$\$" \
  "CUPS" \
  "USB"

rm -f "\$INPUT_PS"
rm -f "\$RCFILE"

exit 0
EOF

    chmod 755 \
      $out/lib/cups/filter/brother_lpdwrapper_ql570
  '';

  meta = with lib; {
    description = "Brother QL-570 proprietary CUPS driver";
    platforms = platforms.linux;
    license = licenses.gpl2Plus;
  };
}