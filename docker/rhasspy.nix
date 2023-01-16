{ config, ... }:
{
  config.virtualisation.oci-containers.containers = {
    rhasspy = {
      image = "rhasspy/rhasspy";
      ports = [ "0.0.0.0:12101:12101" "11111:11111/udp" ];
      extraOptions = ["--device=/dev/snd:/dev/snd"];
      cmd = [ "--user-profiles" "/profiles" "--profile" "en"];
      volumes = [
        "/home/moritz/.config/rhasspy/profiles:/profiles"
        "/etc/localtime:/etc/localtime:ro"
        "/etc/asound.conf:/etc/asound.conf:ro"
      ];
    };
  };
}
