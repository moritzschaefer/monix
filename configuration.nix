# Edit nthis configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, options, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      # <nixos-hardware/raspberry-pi/4>  # maybe needed for sound? also see hardware.raspberry-pi."4" ... below
      ./hardware-configuration.nix
      ./docker/deconz.nix  # deconz for home-assistant
      ./docker/cloudmacs.nix
      ./docker/pihole.nix
      ./docker/rhasspy.nix
      ./homeassistant/default.nix
      ./network/samba.nix
      ./borg.nix
      ./plex.nix
      ./kodi.nix
      ./nature_filter/service.nix
    ];
  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.packageOverrides = 
    let unstable = import <nixos-unstable>  { config = { allowUnfree = true; }; };
    in
      pkgs: {
        nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
          inherit pkgs;
          repoOverrides = {
            # mic92 = import (builtins.fetchTarball "https://github.com/mweinelt/nur-packages-mic92/archive/master.tar.gz");
          };
        };
        unstable = unstable;
        # lapack = unstable.lapack;
        # blas = unstable.blas;
        # openfst = unstable.openfst;
	# flake8 = unstable.flake8;
	# glibc = unstable.glibc;
        # opengrm-ngram = unstable.opengrm-ngram;
        # home-assistant = unstable.home-assistant;
        python3 = pkgs.python39;
        python3Packages = pkgs.python3Packages;
	#python = unstable.python3.override {    
            #packageOverrides = self: super: rec {
                #botocore = unstable.python37Packages.botocore;
                #boto3 = unstable.python37Packages.boto3;
	    #};
        #};
      };

  nixpkgs.overlays = [ (import ./overlays/python-packages.nix) ];
  hardware.enableRedistributableFirmware = true;

  
  nix = {
    autoOptimiseStore = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    # Free up to 1GiB whenever there is less than 100MiB left.
    extraOptions = ''
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (1024 * 1024 * 1024)}
    '';
  };
  boot = {
    kernelPackages = pkgs.linuxPackages_rpi4;
    tmpOnTmpfs = true;
    kernelParams = [
        "8250.nr_uarts=1"
        "console=ttyAMA0,115200"
        "console=tty1"
        # A lot GUI programs need this, nearly all wayland applications
        "cma=128M"
        "snd_bcm2835.enable_headphones=1"
        "snd_bcm2835.enable_hdmi=1" # Add these two to enable HDMI sound
        "snd_bcm2835.enable_compat_alsa=0"
    ];

    loader = {
      grub.enable = false;
      raspberryPi = {
        enable = true;
        version = 4;
      uboot = {
        # enable = true;  # either its enabled or not. idk...
        configurationLimit = 1;
      };
        firmwareConfig = ''

# Enable sound or so...
dtparam=audio=on
# hdmi_ignore_edid=0xa5000080 (only required for shity chinese TVs) 
disable_overscan=1
hdmi_force_hotplug=1
# HDMI auch ohne Monitor in Betrieb nehmen (optional)
hdmi_force_hotplug=1
# Audio über HDMI ausgeben (optional)
# hdmi_drive=2
# CEA-Betriebsmodus aktivieren (CEA=1, 4K/30=100)
hdmi_group:0=1
hdmi_mode:0=100'';
      };
    };
  };
  # hardware.raspberry-pi."4" = {
  #   fkms-3d.enable = true;
  #   audio.enable = true;
  #   dwc2.enable = true;
  # };

  hardware.bluetooth.enable = true;
  # Use the GRUB 2 boot loader.
  # boot.loader.grub.enable = true;
  # boot.loader.grub.version = 2;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  # boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  #
  # };
  nixpkgs.config.permittedInsecurePackages = [
    "homeassistant-0.114.4"
  ];

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.variables = { EDITOR = "vim"; };
  environment.systemPackages = with pkgs; let myneovim = (neovim.override {
      vimAlias = true;
      configure = {
        packages.myPlugins = with pkgs.vimPlugins; {
          start = [ ]; #spacevim ]; 
          opt = [];
        };
        customRC = ''
          " your custom vimrc
          set nocompatible
          set backspace=indent,eol,start
          "
        '';
      };
    }
  ); 
  mypython =  python3.withPackages (python-packages: [ python-packages.rpi-gpio python-packages.fritzconnection]);
  in [
    arp-scan nmap wget emacs tmux curl htop git myneovim mypython 
    ffmpeg
    # nur.repos.mic92.rhasspy  # just use docker for now :)
    usbutils pciutils libraspberrypi 
    wireguard-tools
    ncdu
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  #   pinentryFlavor = "gnome3";
  # };

  # Networking
  networking = {
    hostName = "monix";
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
    wireless.enable = false; 
    networkmanager.enable = true;
    nat = {  # NAT
      enable = true;
      externalInterface = "wlan0";
      internalInterfaces = [ "wg0" ];
    };
    firewall.allowedUDPPorts = [ 51820 ];
    firewall.allowedTCPPorts = [ 51821 8384 21 ];  # syncthing as well, and FTP
  };

  networking.wireguard.interfaces = {
    # "wg0" is the network interface name. You can name the interface arbitrarily.
    wg0 = {
      # Determines the IP address and subnet of the server's end of the tunnel interface.
      ips = [ "10.100.0.1/24" ];

      # The port that WireGuard listens to. Must be accessible by the client.
      listenPort = 51820;

      # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
      # For this to work you have to set the dnsserver IP of your router (or dnsserver of choice) in your clients
      postSetup = ''
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
      '';

      # This undoes the above command
      postShutdown = ''
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
      '';

      # Path to the private key file.
      #
      # Note: The private key can also be included inline via the privateKey option,
      # but this makes the private key world-readable; thus, using privateKeyFile is
      # recommended.
      privateKeyFile = "/home/moritz/.wireguard/private_key";

      peers = [
        # List of allowed peers.
        { # Feel free to give a meaning full name
          # Public key of the peer (not a file path).
          publicKey = "jt+CtENSgKth7oXAmbb/jEyhtovwIz1RJIp5eWXIkz8=";
          # List of IPs assigned to this peer within the tunnel subnet. Used to configure routing.
          allowedIPs = [ "10.100.0.2/32" ];
        }
      ];
    };
  };
  # DuckDNS
  #
  services.ddclient = {
    enable = true;
    domains = [ "moritzs.duckdns.org" ];
    protocol = "duckdns";
    server = "www.duckdns.org";
    username = "nouser";
    passwordFile = "/root/duckdns_password";
  };

  services.nature_filter = {
    enable = false; # feedly fucks
  };


  # FTP server
  services.vsftpd = {
    enable = false;
#   cannot chroot && write
#    chrootlocalUser = true;
    writeEnable = true;
    localUsers = true;
    userlist = [ "moritz" ];
    anonymousUserHome = "/mnt/hdd3tb/ftp_anon/";
    userlistEnable = true;
    anonymousUser = true;
    anonymousUploadEnable = true;
    anonymousMkdirEnable = true;
  };
  # networking.firewall.allowedTCPPorts = [ 21 ]; # defined elsewhere
  services.vsftpd.extraConfig = ''
	  pasv_enable=Yes
	  pasv_min_port=51000
	  pasv_max_port=51800
	  '';
  networking.firewall.allowedTCPPortRanges = [ { from = 51000; to = 51800; } ];



  services.nscd.enable = true;
  services.avahi = {
    enable = true;
    publish = {
      addresses = true;
      workstation = true;
      enable = true;
    };
  };
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];

  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
    passwordAuthentication = true;
  };
  users.users.moritz = {
    isNormalUser = true;
    home = "/home/moritz";
    extraGroups = [ "wheel" "networkmanager" "dialout" "docker" "gpio" "audio" ];
    openssh.authorizedKeys.keys = [ "" ];
  };
  users.users.hass = {
    extraGroups = [ "gpio" "dialout" "audio" ];
  };
  virtualisation.docker.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
  };
  nixpkgs.config.pulseaudio = true;


  sound.extraConfig = (builtins.readFile ./asound.conf);  # combine microphones..
  systemd.packages = [ pkgs.spotifyd ];
  systemd.user.services.spotifyd = let
    username=(lib.strings.fileContents ./spotify_pass/username); 
    password=(lib.strings.fileContents ./spotify_pass/password);
    config = pkgs.writeText "spotifyd.conf" ''
      [global]
      username = "${username}"
      password = "${password}"
      use_keyring = false
      backend = "pulseaudio"
      bitrate = 160
      device_name = "Monix Pi"
      no_audio_cache = true
    '';
  in {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "sound.target" ];
      # description = "spotifyd, a Spotify playing daemon";
      serviceConfig = {
        ExecStart = "${pkgs.spotifyd}/bin/spotifyd --no-daemon --config-path ${config}";
        Restart = "always";
        RestartSec = 12;
      };
  };
  # this one is buggy unfordunately..
  services.spotifyd = {
    enable = false;
    config = 
    let username=(lib.strings.fileContents ./spotify_pass/username); password=(lib.strings.fileContents ./spotify_pass/password); in ''
      [global]
      username = ${username}
      password = ${password}
      use_keyring = false
      backend = pulseaudio
      bitrate = 160
      device_name = Monix Pi
      no_audio_cache = true
  '';
  };

  # Syncthing
  services.syncthing = {
    enable = true;
    guiAddress="0.0.0.0:8384";
    package = pkgs.unstable.syncthing;
    user = "moritz";
    dataDir = "/home/moritz/Syncthing";
    configDir = "/home/moritz/.config/syncthing";
    openDefaultPorts = true;
  };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.

  #services.xserver = {
    #enable = true;
    #displayManager.sddm.enable = true;
    #desktopManager.gnome3.enable = true;
  #};

  # this is very liberal (222 should be 220 and 666 should be 660), but I don't want any struggle with access because of groups..
  services.udev.extraRules = let
    gpio_chip_udev_script = pkgs.writeShellScript "gpio_chip_udev_script" "chown root:gpio /sys/class/gpio/export /sys/class/gpio/unexport ; chmod 222 /sys/class/gpio/export /sys/class/gpio/unexport";
    # gpio_udev_script = pkgs.writeShellScript "gpio_udev_script" "chown root:gpio /sys%p/active_low /sys%p/direction /sys%p/edge /sys%p/value ; chmod 666 /sys%p/active_low /sys%p/direction /sys%p/edge /sys%p/value";
    gpio_udev_script = pkgs.writeShellScript "gpio_udev_script" "echo %k %n %p %b %b %M %m %c %P $name $links %r %S >> /tmp/$(date +%s)";
  in ''
    SUBSYSTEM=="bcm2835-gpiomem", KERNEL=="gpiomem", GROUP="gpio", MODE="0666"
    SUBSYSTEM=="gpio", KERNEL=="gpiochip*", ACTION=="add", RUN+="${gpio_chip_udev_script}"
    SUBSYSTEM=="gpio", KERNEL=="gpio*", ACTION=="add", RUN+="${gpio_udev_script}"
  '';

  # systemd.services.rhasspy = {
    # after = [ "network.target" ];
    # wantedBy = [ "multi-user.target" ];
    # # rhasspy sets `/dev/stdout` as log file for supervisord
    # # supervisord tries to open /dev/stdout and fails with the default systemd device
    # # it works for pipes so...
    # script = ''
      # ${pkgs.nur.repos.mic92.rhasspy}/bin/rhasspy --profile en | ${pkgs.utillinux}/bin/logger
    # '';
    # serviceConfig = {
      # User = "moritz";
      # # needed for pulseaudio
      # Environment = "XDG_RUNTIME_DIR=/run/user/1001"; # pi is 1000
    # };
  # };
  

  services.node-red = {
    enable = true;
    openFirewall = true;
    withNpmAndGcc = true;
  };

  time.timeZone = "Europe/Zurich";
  services.localtime.enable = true;


  # https://nixos.wiki/wiki/Overlays
  # Prepend default nixPath values.
  nix.nixPath = options.nix.nixPath.default ++ 
    # Append our nixpkgs-overlays.
    [ "nixpkgs-overlays=/etc/nixos/overlays-compat/" ]
  ;

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "20.09"; # Did you read the comment?
}

