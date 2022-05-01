{ config, ... }:
{
  config.virtualisation.oci-containers.containers = {
    # deconz = {
      # image = "deconzcommunity/deconz:latest";
      # ports = [ "127.0.0.1:8124:80" "127.0.0.1:443:443" ];
      # extraOptions = [ "--device=/dev/ttyUSB0" ];
      # volumes = [
       # "/opt/deconz:/opt/deCONZ"
        # "/etc/localtime:/etc/localtime:ro"
      # ];
    # };
  }; 
}
