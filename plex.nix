{ ... }:
{
  services.plex = {
    enable = true;
    openFirewall = true;
    dataDir = "/mnt/sdd2tb/plex";
  };
}
