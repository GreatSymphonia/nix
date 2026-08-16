{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  glib,
  gtk3,
  libayatana-appindicator,
  libcap_ng,
  libdrm,
  libglvnd,
  libnotify,
  libseccomp,
  libsecret,
  libgbm,
  libuuid,
  libxcb,
  libxtst,
  nspr,
  nss,
  pango,
  systemd,
  xdg-utils,
}:

let
  version = "1.28929.0";
  debArch = {
    x86_64-linux = "amd64";
    aarch64-linux = "arm64";
  }.${stdenv.hostPlatform.system};
  hash = {
    amd64 = "sha256-POs5Emi96af+wyUg00m3BAQxZiBM3VccYtHpUHAfSPw=";
    arm64 = "sha256-elzr0N/hpBrLo1H1SPLPn4/kmvNsPfyOAv6ynhhs1a4=";
  }.${debArch};

  glLibs = [
    libglvnd
    libgbm
  ];
  libs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    glib
    gtk3
    libayatana-appindicator
    libcap_ng
    libdrm
    libnotify
    libseccomp
    libsecret
    libuuid
    nspr
    nss
    pango
    systemd
    libxcb
    libxtst
  ];
  runpathPackages = glLibs ++ libs ++ [
    stdenv.cc.cc
    stdenv.cc.libc
  ];
in
stdenv.mkDerivation {
  pname = "claude-desktop";
  inherit version;

  src = fetchurl {
    url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_${debArch}.deb";
    inherit hash;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
  ];

  buildInputs = glLibs ++ libs;

  appendRunpaths = map (pkg: "${lib.getLib pkg}/lib") runpathPackages ++ [
    "${placeholder "out"}/lib/claude-desktop"
  ];

  # Needed for Zygote/sandbox, matching Electron's usual runtime deps.
  runtimeDependencies = [
    systemd
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r usr/* $out
    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/claude-desktop \
      --suffix PATH : "${lib.makeBinPath [ xdg-utils ]}"
  '';

  meta = {
    description = "Desktop application for Claude.ai";
    homepage = "https://claude.ai";
    changelog = "https://code.claude.com/docs/en/desktop-linux";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "claude-desktop";
  };
}
