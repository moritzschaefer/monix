# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, options, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./homeassistant/main.nix
    ];


  nixpkgs.overlays = [ (import ./overlays/python-packages.nix) ];
  boot.loader.grub.enable = false;
  boot.loader.raspberryPi.enable = true;
  boot.loader.raspberryPi.version = 4;
  boot.kernelPackages = pkgs.linuxPackages_rpi4;

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
  # };

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget vim emacs tmux curl htop git skopeo python3.pydeconz
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
    extraGroups = [ "wheel" "networkmanager" "dialout" "docker" ];
    openssh.authorizedKeys.keys = [ "" ];
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
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.jane = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  # };

  services.home-assistant = {
    enable = true;
    port = 8123;
    openFirewall = true;
    applyDefaultConfig = false;
    package = pkgs.home-assistant.override {
      extraPackages = ps: with ps; [ colorlog ];
      packageOverrides = self: super: {
        pydeconz = pkgs.pythonPackages.pydeconz;
      };
    };
    

    config = {
      homeassistant = {
        name = "Home";
        time_zone = "Europe/Zurich"; 
        latitude = 1;
        longitude = 1;
        elevation = 1;
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
        default = "info";
        logs = {
          pydeconz = "debug";
          "homeassistant.components.deconz" = "debug";
        };
      };
    };
  };
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
  system.stateVersion = "20.03"; # Did you read the comment?
}

