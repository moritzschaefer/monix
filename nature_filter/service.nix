# see https://blog.stigok.com/2019/11/05/packing-python-script-binary-nicely-in-nixos.html
{ config, lib, pkgs, ... }:

let
    # The package itself. It resolves to the package installation directory.
    nature_filter = pkgs.callPackage ./default.nix {};

    # An object containing user configuration (in /etc/nixos/configuration.nix)
    cfg = config.services.nature_filter;

    # Build a command line argument if user chose direction option
    # portArg = if cfg.port == ""
    #                then ""
    #                else "--port=${cfg.port} ";
in {
    # Create the main option to toggle the service state
    options.services.nature_filter.enable = lib.mkEnableOption "nature_filter";

    # The following are the options we enable the user to configure for this
    # package.
    # These options can be defined or overriden from the system configuration
    # file at /etc/nixos/configuration.nix
    # The active configuration parameters are available to us through the `cfg`
    # expression.

    # options.services.nature_filter.host = lib.mkOption {
    #     type = lib.types.str;
    #     default = "0.0.0.0";
    #     example = "127.0.0.1";
    # };
    # options.services.nature_filter.port = lib.mkOption {
    #     type = lib.types.int;
    #     default = 9999;
    # };
    # options.services.nature_filter.extraArgs = lib.mkOption {
    #     type = lib.types.listOf lib.types.str;
    #     default = [""];
    #     example = ["--debug"];
    # };

    # Everything that should be done when/if the service is enabled
    config = lib.mkIf cfg.enable {
        # Open selected port in the firewall.
        # We can reference the port that the user configured.
        networking.firewall.allowedTCPPorts = [ 80 443 ]; # cfg.port
	services.nginx = {
	    recommendedProxySettings = true;
            recommendedTlsSettings = true;
	    enable = true;
	};
	security.acme.acceptTerms = true;
	security.acme.defaults.email = "mollitz@gmail.com";
	services.nginx.virtualHosts."moritzs.duckdns.org" = {
          enableACME = true;
          forceSSL = false;  # should set to true after let's encrypt works
          locations."/" = {
            proxyPass = "http://127.0.0.1:9999";
            proxyWebsockets = false; # needed if you need to use WebSocket
          };
        };

        # Describe the systemd service file
        systemd.services.nature_filter = {
            description = "Filtering and hosting nature RSS feed";
            environment = {
                PYTHONUNBUFFERED = "1";
            };

            # Wait not only for network configuration, but for it to be online.
            # The functionality of this target is dependent on the system's
            # network manager.
            # Replace the below targets with network.target if you're unsure.
            after = [ "network-online.target" ];
            wantedBy = [ "network-online.target" ];

            # Many of the security options defined here are described
            # in the systemd.exec(5) manual page
            # The main point is to give it as few privileges as possible.
            # This service should only need to talk HTTP on a high numbered port
            # -- not much more.
            serviceConfig = {
                DynamicUser = "true";
                PrivateDevices = "true";
                ProtectKernelTunables = "true";
                ProtectKernelModules = "true";
                ProtectControlGroups = "true";
                RestrictAddressFamilies = "AF_INET AF_INET6";
                LockPersonality = "true";
                RestrictRealtime = "true";
                SystemCallFilter = "@system-service @network-io @signal";
                SystemCallErrorNumber = "EPERM";
                # See how we can reference the installation path of the package,
                # along with all configured options.
                # The package expression `nature_filter` expands to the root
                # installation path.
                ExecStart = "${nature_filter}/bin/nature_filter";  # --host ${cfg.host} --port ${tostring cfg.port}   " " cfg.extraargs
                restart = "always";
                restartsec = "5";
            };
        };
    };
}
