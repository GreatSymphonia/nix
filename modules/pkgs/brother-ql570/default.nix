{ lib
, stdenv
, gcc
, bash
, cups
, coreutils
, gnused
, gnugrep
, gawk
, file
, psutils
, ghostscript
, which
, patchelf
, pkgsi686Linux
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
  dontConfigure = true;

  nativeBuildInputs = [
    gcc
    file
    patchelf
  ];

  buildInputs = [
    bash
    cups
    coreutils
    gnused
    gnugrep
    gawk
    file
    psutils
    ghostscript
    which
    pkgsi686Linux.glibc
  ];

  buildPhase = ''
    runHook preBuild

    cp -r ${cupswrapperSrc} cupswrapper
    cp -r ${lprSrc} lpr

    chmod -R u+w cupswrapper
    chmod -R u+w lpr

    #
    # Patch brcupsconfig.c for modern GCC/glibc.
    #
    cat > cupswrapper/brcupsconfig/brcupsconfig-patched.c <<'EOF'
#include <stdlib.h>
EOF

    cat cupswrapper/brcupsconfig/brcupsconfig.c \
      >> cupswrapper/brcupsconfig/brcupsconfig-patched.c

    #
    # Avoid crashes in divide_media_token().
    #
    sed -i \
      's/strcpy(media_command,p+strlen(MEDIAEQ1));/strncpy(media_command,p+strlen(MEDIAEQ1),sizeof(media_command)-1); media_command[sizeof(media_command)-1]=0;/' \
      cupswrapper/brcupsconfig/brcupsconfig-patched.c

    sed -i \
      's/strcpy(media_command,p+strlen(MEDIAEQ2));/strncpy(media_command,p+strlen(MEDIAEQ2),sizeof(media_command)-1); media_command[sizeof(media_command)-1]=0;/' \
      cupswrapper/brcupsconfig/brcupsconfig-patched.c

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
      psutils
      ghostscript
      which
      cups
    ]}:$out/bin"

    I686_LD="${pkgsi686Linux.glibc}/lib/ld-linux.so.2"
    I686_LIB="${pkgsi686Linux.glibc}/lib"

    mkdir -p $out

    #
    # Install Brother LPR driver tree.
    #
    cp -r lpr/opt $out/

    #
    # Install Brother userland tools, including brprintconfpt1_ql570.
    #
    mkdir -p $out/bin

    if [ -d lpr/usr/bin ]; then
      for f in lpr/usr/bin/*; do
        install -Dm755 "$f" "$out/bin/$(basename "$f")"
      done
    fi

    #
    # Ensure cupswrapper directory exists.
    #
    mkdir -p \
      $out/opt/brother/PTouch/ql570/cupswrapper

    install -m755 \
      brcupsconfpt1 \
      $out/opt/brother/PTouch/ql570/cupswrapper/brcupsconfpt1

    #
    # Patch hardcoded /opt/brother paths in Brother shell scripts.
    #
    substituteInPlace \
      $out/opt/brother/PTouch/ql570/lpd/filterql570 \
      --replace "/opt/brother" "$out/opt/brother"

    #
    # Brother's script expects pstops in /usr/bin.
    # On NixOS, pstops comes from psutils.
    #
    substituteInPlace \
      $out/opt/brother/PTouch/ql570/lpd/filterql570 \
      --replace 'PSTOPS_PATH="/usr/bin/pstops"' \
                "PSTOPS_PATH=\"${psutils}/bin/pstops\""

    #
    # Patch shebangs for shell scripts.
    #
    patchShebangs \
      $out/opt/brother/PTouch/ql570/lpd/filterql570

    if [ -f $out/opt/brother/PTouch/ql570/lpd/psconvertpt1 ]; then
      patchShebangs \
        $out/opt/brother/PTouch/ql570/lpd/psconvertpt1
    fi

    #
    # Inject PATH into Brother shell scripts.
    #
    sed -i "2iexport PATH=$BROTHER_PATH:\$PATH" \
      $out/opt/brother/PTouch/ql570/lpd/filterql570

    if [ -f $out/opt/brother/PTouch/ql570/lpd/psconvertpt1 ]; then
      sed -i "2iexport PATH=$BROTHER_PATH:\$PATH" \
        $out/opt/brother/PTouch/ql570/lpd/psconvertpt1
    fi

    #
    # Patch old i386 ELF binaries.
    #
    for f in \
      $out/opt/brother/PTouch/ql570/lpd/rastertobrpt1 \
      $out/bin/*
    do
      if [ -f "$f" ] && file "$f" | grep -q "ELF 32-bit"; then
        chmod u+w "$f"

        patchelf \
          --set-interpreter "$I686_LD" \
          --set-rpath "$I686_LIB" \
          "$f" || true
      fi
    done

    #
    # Install PPD.
    #
    install -Dm644 \
      cupswrapper/ppd/brother_ql570_printer_en.ppd \
      $out/share/cups/model/brother_ql570_printer_en.ppd

    #
    # Install CUPS filter wrapper.
    #
    mkdir -p $out/lib/cups/filter

    cat > $out/lib/cups/filter/brother_lpdwrapper_ql570 <<EOF
#!${bash}/bin/bash

export PATH=$BROTHER_PATH:\$PATH

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
  >/dev/null || true

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
    description = "Brother QL-570 CUPS driver for NixOS";
    platforms = platforms.linux;
  };
}