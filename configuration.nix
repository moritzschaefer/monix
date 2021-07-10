# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, options, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./homeassistant/main.nix  # deconz docker image (for now)
    ];
  # nixpkgs.config.packageOverrides = super: {
  # python3 = super.python3.override {
    # # Careful, we're using a different self and super here!
    # packageOverrides = self: super: {
      # pydeconz = super.buildPythonPackage rec {
        # pname = "pydeconz";
        # version = "71";
        # # name = "${pname}-${version}";
        # propagatedBuildInputs = [ super.pythonPackages.aiohttp ];
        # doCheck = false;
        # src = super.fetchPypi {
          # inherit pname version;
          # sha256 = "cd7436779296ab259c1e3e02d639a5d6aa7eca300afb03bb5553a787b27e324c";
        # };
      # };
    # };
  # };
  # };
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
        # unstable = unstable;
        # lapack = unstable.lapack;
        # blas = unstable.blas;
        # openfst = unstable.openfst;
	# flake8 = unstable.flake8;
	# glibc = unstable.glibc;
        # opengrm-ngram = unstable.opengrm-ngram;
        # home-assistant = unstable.home-assistant;
        python3 = pkgs.python38;
        python3Packages = pkgs.python3Packages;
	#python = unstable.python3.override {    
            #packageOverrides = self: super: rec {
                #botocore = unstable.python37Packages.botocore;
                #boto3 = unstable.python37Packages.boto3;
	    #};
        #};
      };

  nixpkgs.overlays = [ (import ./overlays/python-packages.nix) ];
  boot.loader.grub.enable = false;
  boot.loader.raspberryPi.enable = true;
  boot.loader.raspberryPi.version = 4;
  boot.kernelPackages = pkgs.linuxPackages_rpi4;

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
    # nur.repos.mic92.rhasspy
    usbutils pciutils libraspberrypi 
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
  };
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
    extraGroups = [ "gpio" "dialout" ];
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
  hardware.pulseaudio.enable = true;
  nixpkgs.config.pulseaudio = true;
  boot.loader.raspberryPi.firmwareConfig = ''
    dtparam=audio=on
  '';
  sound.extraConfig = (builtins.readFile ./asound.conf);  # combine microphones..
  systemd.packages = [ pkgs.spotifyd ];
  systemd.user.services.spotifyd = let
    username=(lib.strings.fileContents ./spotify_pass/username); 
    password=(lib.strings.fileContents ./spotify_pass/password);
    config = pkgs.writeText "spotifyd.conf" ''
      [global]
      username = ${username}
      password = ${password}
      use_keyring = false
      backend = pulseaudio
      bitrate = 160
      device_name = Monix Pi
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
  #   after = [ "network.target" ];
  #   wantedBy = [ "multi-user.target" ];
  #   # rhasspy sets `/dev/stdout` as log file for supervisord
  #   # supervisord tries to open /dev/stdout and fails with the default systemd device
  #   # it works for pipes so...
  #   script = ''
  #     ${pkgs.nur.repos.mic92.rhasspy}/bin/rhasspy --profile en | ${pkgs.utillinux}/bin/logger
  #   '';
  #   serviceConfig = {
  #     User = "moritz";
  #     # needed for pulseaudio
  #     Environment = "XDG_RUNTIME_DIR=/run/user/1001"; # pi is 1000
  #   };
  # };
  

  services.home-assistant = {
    configWritable = true;
    enable = true;
    port = 8123;
    openFirewall = true;
    applyDefaultConfig = false;
    package = (pkgs.home-assistant.overrideAttrs (oldAttrs: { doInstallCheck=false; doCheck=false; checkPhase=""; dontUsePytestCheck=true; dontUseSetuptoolsCheck=true;})).override {
        extraPackages = ps: with ps; [ colorlog rpi-gpio pydeconz defusedxml aioesphomeapi PyChromecast python-nmap pkgs.nmap pyipp pymetno brother pkgs.ffmpeg ha-ffmpeg ];
        packageOverrides = self: super: {
          pydeconz = pkgs.python3Packages.pydeconz;
          rpi-gpio = pkgs.python3Packages.rpi-gpio;
          python-nmap = pkgs.python3Packages.python-nmap;
          # botocore = pkgs.unstable.python3Packages.botocore;
          # boto3 = pkgs.unstable.python3Packages.boto3;
          # ha-ffmpeg = pkgs.unstable.python3Packages.ha-ffmpeg;
	  uvloop = pkgs.python3Packages.uvloop;
	  uvicorn = pkgs.python3Packages.uvicorn;
	  # httpcore = pkgs.unstable.python3Packages.httpcore;
	  pproxy = pkgs.python3Packages.pproxy;
        };
      };

    config = {
      default_config = {};
      device_tracker = [
        #{
          #platform = "bluetooth_tracker";
        #}
	{ 
	  platform = "nmap_tracker";
	  hosts = "192.168.0.222"; # I only need to check my phone..
	  home_interval = 2;
        }
      ];
      
      light = [
        {
        platform = "switch";
        name = "Window ceiling light";
        entity_id = "switch.ceiling_led_pin";
        }
        {
        platform = "switch";
        name = "Wardrobe ceiling light";
        entity_id = "switch.wardrobe_light";
        }
      ];
      group = {
        moritz_lights = {
          name = "Moritz' Lichter";
          entities = [
            "light.window_ceiling_light"
            "light.moritz"
            "light.wardrobe_ceiling_light"
          ];
        };
      };
      input_boolean = {
        window = {
          name = "Controls Window";
          initial = "off";
        };
        monitor = {
          name = "Controls Monitor";
          initial = "off";
        };
      };
      script = {
        indoor_pump = {
          alias = "Water the wardrobe plant for some time";
          description = "Enable the water pump for some time (in seconds)";
          sequence = [
            {
              service = "switch.turn_on";
              data = {
                entity_id = "switch.wardrobe_plant_pump";
              };
            }
            {
              delay = 15;
            }
            {
              service = "switch.turn_off";
              data = {
                entity_id = "switch.wardrobe_plant_pump";
              };
            }
          ];
        };
        outdoor_pump = {
          alias = "Water the tomatoes for some time";
          description = "Enable the water pump for some time (in seconds)";
          sequence = [
            {
              service = "switch.turn_on";
              data = {
                entity_id = "switch.water_pump";
              };
            }
            {
              delay = 60;
            }
            {
              service = "switch.turn_off";
              data = {
                entity_id = "switch.water_pump";
              };
            }
          ];
        };
        close_window = {
          alias = "Close Window";
          description = "Closes window";
          sequence = [
            {
              service = "input_boolean.turn_off";
              data = {
                entity_id = "input_boolean.window";
              };
            }
            {
              service = "switch.turn_on";
              data = {
                entity_id = "switch.window_pin_2";
              };
            }
            {
              service = "switch.turn_off";
              data = {
                entity_id = "switch.window_pin_1";
              };
            }
            {
              service = "switch.turn_on";
              data = {
                entity_id = "switch.window_motor_enabled";
              };
            }
            {
              delay = 2;
            }
            {
              service = "switch.turn_off";
              data = {
                entity_id = "switch.window_pin_2";
              };
            }
            {
              service = "switch.turn_off";
              data = {
                entity_id = "switch.window_motor_enabled";
              };
            }
          ];
        };
        open_window = {
          alias = "Open Window";
          description = "Opens window";
          sequence = [
            {
              service = "input_boolean.turn_on";
              data = {
                entity_id = "input_boolean.window";
              };
            }
            {
              service = "switch.turn_on";
              data = {
                entity_id = "switch.window_pin_1";
              };
            }
            {
              service = "switch.turn_off";
              data = {
                entity_id = "switch.window_pin_2";
              };
            }
            {
              service = "switch.turn_on";
              data = {
                entity_id = "switch.window_motor_enabled";
              };
            }
            {
              delay = 2;
            }
            {
              service = "switch.turn_off";
              data = {
                entity_id = "switch.window_pin_1";
              };
            }
            {
              service = "switch.turn_off";
              data = {
                entity_id = "switch.window_motor_enabled";
              };
            }
          ];
        };
        switch_on_monitor = {
          alias = "Monitor On";
          description = "Opens window";
          sequence = [
            {
              service = "input_boolean.turn_on";
              data = {
                entity_id = "input_boolean.monitor";
              };
            }
            {
              service = "shell_command.switch_on_monitor";
            }
          ];
        };
        switch_off_monitor = {
          alias = "Monitor off";
          description = "Opens window";
          sequence = [
            {
              service = "input_boolean.turn_off";
              data = {
                entity_id = "input_boolean.monitor";
              };
            }
            {
              service = "shell_command.switch_off_monitor";
            }
          ];
        };
      };
      automation = [
        {
          id =  "open_window_day";
          alias =  "Open the window in the evening";
          trigger =  [
            {
              at =  "22:15";
              platform =  "time";
            }
          ];
          action =  [
            {
              service =  "script.open_window";
            }
          ];
        }
        {
          id =  "1570373794255";
          alias =  "Close window in the night before asswhole animal truck";
          trigger =  [
            {
              at =  "4:45";
              platform =  "time";
            }
          ];
          condition =  {
            condition =  "time";
            weekday =  [
              "mon"
              "thu"
            ];
          };
          action =  [
            {
              service =  "script.close_window";
            }
          ];
        }
        {
          id =  "tierspital_window_close_automation";
          alias =  "Close window in the night before asswhole tierspital starts making noise";
          trigger =  [
            {
              at =  "5:35";
              platform =  "time";
            }
          ];
          condition =  {
            condition =  "time";
            weekday =  [
              "tue"
              "wed"
              "fri"
            ];
          };
          action =  [
            {
              service =  "script.close_window";
            }
          ];
        }
        {
          id =  "church_window_close_automation";
          alias =  "Close window in the night before asswhole church starts making noise";
          trigger =  [
            {
              at =  "8:30";
              platform =  "time";
            }
          ];
          condition =  {
            condition =  "time";
            weekday =  [
              "sun"
              "sat"
            ];
          };
          action =  [
            {
              service =  "script.close_window";
            }
          ];
        }
        {
          id =  "leave_lights_off";
          alias =  "Turn off light when I leave";
          trigger =  {
            platform =  "state";
            entity_id =  "person.moritz";
            to =  "not_home";
          };
          action =  [
            {
              service =  "light.turn_off";
              entity_id =  "group.moritz_lights";
            }
          ];
        }
        {
          id =  "home_lights_on";
          alias =  "Turn on light when I come home";
          trigger =  {
            platform =  "state";
            entity_id =  "person.moritz";
            to =  "home";
          };
          action =  [
            {
              service =  "light.turn_on";
              entity_id =  "group.moritz_lights";
            }
          ];
        }
        {
          id = "water_indoor";
          alias = "Water the wardrobe plant every 4 hours during the day";
          trigger = {
            platform = "time_pattern";
            hours = "/4";
          };
          condition = {
            condition = "time";
            after = "10:00:00";
            before = "20:00:00";
          };
          action = [
            {
              service = "script.indoor_pump";
            }
          ];
        }
        {
          id = "water_tomatoes";
          alias = "Water the plants every hour during the day";
          trigger = {
            platform = "time_pattern";
            hours = "/1";
          };
          condition = {
            condition = "time";
            after = "10:00:00";
            before = "21:00:00";
          };
          action = [
            {
              service = "script.outdoor_pump";
            }
          ];
        }
        {
          id =  "rhasspy_light_onoff";
          alias =  "Voice controlled light";
          trigger =  {
            platform =  "event";
            event_type =  "rhasspy_ChangeLightState";
          };
          action =  {
            service_template =  "light.turn_{{ trigger.event.data[\"state\"] }}\n";
            data_template =  {
              entity_id =  "{{ trigger.event.data[\"name\"] }}";
            };
          };
        }
        {
          id =  "rhasspy_window_open";
          alias =  "Voice controlled window open";
          trigger =  {
            platform =  "event";
            event_type =  "rhasspy_OpenWindow";
          };
          action =  [
            {
              service =  "script.open_window";
            }
          ];
        }
        {
          id =  "rhasspy_window_close";
          alias =  "Voice controlled window close";
          trigger =  {
            platform =  "event";
            event_type =  "rhasspy_CloseWindow";
          };
          action =  [
            {
              service =  "script.close_window";
            }
          ];
        }
      ];


      switch = [{
        platform = "rpi_gpio";
        ports = {
          "18" = "window_motor_enabled";
          "15" = "window_pin_1";
          "14" = "window_pin_2";
          "23" = "ceiling_led_pin";
        };
      } {
        platform = "template";
        switches = {
          window = {
            friendly_name = "Window";
            value_template = "{{ is_state(\"input_boolean.window\", \"on\") }}";
            turn_on =
              {service = "script.open_window";};
            turn_off =
              {service = "script.close_window";};
            };
          monitor = {
            friendly_name = "Monitor";
            value_template = "{{ is_state(\"input_boolean.monitor\", \"on\") }}";
            turn_on =
              {service = "script.switch_on_monitor";};
            turn_off =
              {service = "script.switch_off_monitor";};
          };
        };
      }];
      ffmpeg = {
        # ffmpeg_bin = "/run/current-system/sw/bin/ffmpeg";
      };
      binary_sensor = [{
        platform = "ffmpeg_noise";
        initial_state = true;
        input = "-f alsa -i plughw:2 -sample_rate 44100";
        peak = -32;
        duration = 1;
        reset = 150;
      }];

      homeassistant = {
        name = "Home";
        time_zone = "Europe/Zurich"; 
        latitude = 47.401092299999995; 
        longitude = 8.5537682;
        elevation = 473;
        unit_system = "metric";
        temperature_unit = "C";
      };
      # Enable the frontend
      frontend = {};
      http = {};
      config = {};
      discovery = {
        ignore = [ ];
      };
      logger = {
        default = "warning";
        logs = {
          pydeconz = "debug";
          "homeassistant.components.deconz" = "debug";
        };
      };
    };
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

