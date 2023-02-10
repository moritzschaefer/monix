# https://nixos.wiki/wiki/Borg_backup
{ config, ... }:
{
  services.borgbackup.jobs =
    let common-excludes = [
          # Largest cache dirs
          "*/venv"
          "*/.venv"
          "*/.conda"
        ];
        borg-dirs = {
          wiki="/mnt/sdd2tb/wiki";
          media="/mnt/sdd2tb/Media";
          pi-home="/home/moritz";
          var-lib="/var/lib";
          var-backup="/var/backup";  # for now only postgresql
        };
        basicBorgJob = name: {
          encryption.mode = "none";
          # environment.BORG_RSH = "ssh -o 'StrictHostKeyChecking=no' -i /home/moritz/.ssh/id_ed25519";
          environment.BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK = "yes";
          extraCreateArgs = "--verbose --stats --checkpoint-interval 600";
          repo = "/mnt/hdd3tb/borg/${name}";
          compression = "zstd,1";
          startAt = "daily";  # this means "*-*-* 00:00:00"
          user = "moritz";
          prune.keep = {
            within = "1d"; # Keep all archives from the last day
            daily = 7;
            weekly = 4;
            monthly = 6; # half a year monthly
            yearly = -1; # every year one backup forever (maybe I should change this at some point?)
          };
        };
  in builtins.mapAttrs (name: value:
    basicBorgJob name // rec {
      paths = value;
      exclude = map (x: paths + "/" + x) common-excludes;
    }) borg-dirs;
}

