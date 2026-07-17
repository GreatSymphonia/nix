{ ... }:

{
  # Utilisateur
  users.users.louis = {
    isNormalUser = true;
    description = "Louis Raymond";
    extraGroups = [ "networkmanager" "wheel" "wireshark" "docker" "libvirtd" ];
  };
}