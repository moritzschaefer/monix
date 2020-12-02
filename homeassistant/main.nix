{ config, ... }:
{
 # config.virtualisation.oci-containers.containers = {
  config.docker-containers = {
    deconz = {
      image = "marthoc/deconz:latest";
      ports = ["127.0.0.1:8124:80"];
      extraDockerOptions = [ "--device=/dev/ttyUSB0" ];
      volumes = [
        "/opt/deconz:/root/.local/share/dresden-elektronik/deCONZ"
        "/etc/localtime:/etc/localtime:ro"
      ];
    };
  }; 
}
