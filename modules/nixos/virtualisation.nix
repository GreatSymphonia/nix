{ pkgs, ... }:

{
  virtualisation.docker.package = pkgs.docker_29;
  virtualisation.docker.enable = true;
}