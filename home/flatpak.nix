{ ... }: {
  services.flatpak = {
    enable = true;

    remotes = [
      {
        name     = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];

    packages = [
      { appId = "org.signal.Signal"; origin = "flathub"; }
    ];
  };
}
