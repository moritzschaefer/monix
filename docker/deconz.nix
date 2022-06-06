{ config, ... }:
{
  config.virtualisation.oci-containers.containers = {
    deconz = {
      image = "deconzcommunity/deconz";
      ports = [ "0.0.0.0:8124:80" "0.0.0.0:443:443" ];
      extraOptions = [ "--device=/dev/ttyUSB0:/dev/ttyUSB0:rwm"  "--expose" "5900" "--expose" "6080"];  # I think the exposes can be deleted
      volumes = [
       "/var/lib/deconz:/opt/deCONZ"
        "/etc/localtime:/etc/localtime:ro"
      ];
    };
  }; 
}
