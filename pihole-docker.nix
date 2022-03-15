# could also use dnsmasq (see here: https://github.com/NixOS/nixpkgs/issues/61617) 
{ config, ... }:
{
  config.docker-containers.pihole = let serverIP = "192.168.0.10"; in {
    image = "pihole/pihole:latest";
    ports = [
      "${serverIP}:53:53/tcp"
      "${serverIP}:53:53/udp"
      "3080:80"
      "30443:443"
    ];
    volumes = [
      "/var/lib/pihole/:/etc/pihole/"
      "/var/lib/dnsmasq.d:/etc/dnsmasq.d/"
    ];
    environment = {
      ServerIP = serverIP;
    };
    extraDockerOptions = [
      "--cap-add=NET_ADMIN"
      "--dns=127.0.0.1"
      "--dns=1.1.1.1"
    ];
    workdir = "/var/lib/pihole/";
  };
}
