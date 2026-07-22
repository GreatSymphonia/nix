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
      { appId = "org.signal.Signal";            origin = "flathub"; }
      { appId = "com.discordapp.Discord";       origin = "flathub"; }
      { appId = "me.drewol.Unnamed-SDVX-Clone"; origin = "flathub"; }
    ];

    overrides."me.drewol.Unnamed-SDVX-Clone".Context.devices = "input;";
  };
}
