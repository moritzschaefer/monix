{ config, ... }:
{
  config.virtualisation.oci-containers.containers = {
    cloudmacs = {
      image = "karlicoss/cloudmacs:latest";
      ports = ["8080:8080"];
      extraOptions = [ "--restart=unless-stopped" 
                       "-i" "-t" 
		       "-e" "UNAME=moritz"
		       "-e" "GNAME=users" 
		       "-e" "EMACS_UID=1001" 
		       "-e" "EMACS_GID=100" 
		       "-e" "UHOME=/home/emacs" 
		       "-e" "UNAME=xterm-256color" 
		     ];
      volumes = [
        "/home/moritz/dotfiles/home/.spacemacs.d:/home/emacs/.spacemacs.d"
        "/home/moritz/.cloudmacs.d:/home/emacs/.emacs.d"
        "/mnt/sdd2tb/wiki:/home/emacs/wiki"
      ];
    };
  }; 
}
