{ lib
, stdenv
, gcc
, cups
, file
, bash
, coreutils
, gnused
, gnugrep
, gawk
, brotherQl570Sources
}:

let
  cupswrapperSrc = brotherQl570Sources.cupswrapper;
  lprSrc = brotherQl570Sources.lpr;
in

stdenv.mkDerivation rec {
  pname = "brother-ql570";
  version = "1.0.1";

  dontUnpack = true;

  nativeBuildInputs = [
    gcc
  ];

  buildInputs = [
    cups
    bash
    coreutils
    gnused
    gnugrep
    gawk
    file
  ];

  buildPhase = ''
    runHook preBuild

    cp -r ${cupswrapperSrc} cupswrapper
    cp -r ${lprSrc} lpr

    chmod -R u+w cupswrapper
    chmod -R u+w lpr

    cat > cupswrapper/brcupsconfig/brcupsconfig-patched.c <<'EOF'
#include <stdlib.h>
EOF

    cat cupswrapper/brcupsconfig/brcupsconfig.c \
      >> cupswrapper/brcupsconfig/brcupsconfig-patched.c

    sed -i \
      's/strcpy(output\[i\],p);/strncpy(output[i],p,29); output[i][29]=0;/' \
      cupswrapper/brcupsconfig/brcupsconfig-patched.c

    gcc \
      -O0 \
      -U_FORTIFY_SOURCE \
      -D_FORTIFY_SOURCE=0 \
      -fno-stack-protector \
      -Icupswrapper/brcupsconfig \
      -o brcupsconfpt1 \
      cupswrapper/brcupsconfig/brcupsconfig-patched.c

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    BROTHER_PATH="${lib.makeBinPath [
      coreutils
      gnused
      gnugrep
      gawk
      file
      cups
    ]}"

    mkdir -p $out

    #
    # Brother tree
    #
    mkdir -p $out/opt/brother/PTouch/ql570

    cp -r lpr/* \
      $out/opt/brother/PTouch/ql570/

    cp -r cupswrapper/* \
      $out/opt/brother/PTouch/ql570/

    mkdir -p \
      $out/opt/brother/PTouch/ql570/cupswrapper

    install -m755 \
      brcupsconfpt1 \
      $out/opt/brother/PTouch/ql570/cupswrapper/brcupsconfpt1

    #
    # Patch chemins hardcodés
    #
    substituteInPlace \
      $out/opt/brother/PTouch/ql570/lpd/filterql570 \
      --replace "/opt/brother" "$out/opt/brother"

    #
    # pstops n'existe pas dans /usr/bin sous NixOS
    #
    substituteInPlace \
      $out/opt/brother/PTouch/ql570/lpd/filterql570 \
      --replace 'PSTOPS_PATH="/usr/bin/pstops"' \
                'PSTOPS_PATH="${cups}/bin/pstops"'

    patchShebangs \
      $out/opt/brother/PTouch/ql570/lpd/filterql570

    #
    # PATH pour les utilitaires GNU
    #
    sed -i '2i\
export PATH='"${BROTHER_PATH}"':$PATH
' \
      $out/opt/brother/PTouch/ql570/lpd/filterql570

    #
    # PPD
    #
    install -Dm644 \
      cupswrapper/ppd/brother_ql570_printer_en.ppd \
      $out/share/cups/model/brother_ql570_printer_en.ppd

    #
    # Wrapper CUPS
    #
    mkdir -p $out/lib/cups/filter

    cat > $out/lib/cups/filter/brother_lpdwrapper_ql570 <<EOF
#!${bash}/bin/bash

export PATH=${BROTHER_PATH}:\$PATH

PPDC=\$(printenv | sed -n 's/^PPD=//p')

if [ -z "\$PPDC" ]; then
  PPDC="$out/share/cups/model/brother_ql570_printer_en.ppd"
fi

RCFILE="/tmp/brql570rc_\$\$"

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
  CUPS \
  USB

rm -f "\$INPUT_PS"
rm -f "\$RCFILE"

exit 0
EOF

    chmod 755 \
      $out/lib/cups/filter/brother_lpdwrapper_ql570

    runHook postInstall
  '';

  meta = with lib; {
    description = "Brother QL-570 driver";
    platforms = platforms.linux;
  };
}