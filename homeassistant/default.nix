{ lib, config, pkgs, options, ... }:

{
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "hass" ];
    ensureUsers = [{
      name = "hass";
      ensurePermissions = {
        "DATABASE hass" = "ALL PRIVILEGES";
      };
    }];
  };
  services.postgresqlBackup = {
    enable = true;
    startAt = "*-*-* 23:00:00";  # Start before borg (which is at 12)
  };
  services.home-assistant = {
    configWritable = true;
    enable = true;
    # config.http.server_port = 8123;
    openFirewall = true;
    package = (pkgs.home-assistant.overrideAttrs (oldAttrs: { doInstallCheck=false; doCheck=false; checkPhase=""; dontUsePytestCheck=true; dontUseSetuptoolsCheck=true;})).override {
        extraPackages = ps: with ps; [ colorlog rpi-gpio pydeconz defusedxml aioesphomeapi PyChromecast python-nmap pkgs.nmap pyipp pymetno brother pkgs.ffmpeg ha-ffmpeg psycopg2 ];
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
    extraComponents = [
        "webostv"
      ];

    config = {
      default_config = {};
      backup = {};
      wake_on_lan = {};
      recorde.db_url = "postgresql://@/hass";
      device_tracker = [
        #{
          #platform = "bluetooth_tracker";
        #}
	{
	  platform = "nmap_tracker";
	  hosts = "192.168.0.220"; # I only need to check my phone..
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
      automation = {
      "automation manual"=
      [
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
          id =  "tierspital_noise_close_automation";
          alias =  "Close window during night when there is noise";
          trigger =  [
            {
              to =  "on";
              platform =  "state";
              entity_id = "binary_sensor.outdoor_noise";
            }
          ];
          condition =  {
            condition =  "time";
            after = "22:30:00";  # TODO 22
            before = "7:00:00";
          };
          action =  [
            {
              service =  "script.close_window";
            }
          ];
        }
        {
          id =  "tierspital_noise_open_automation";
          alias =  "Open window during night when there is no more noise";
          trigger =  [
            {
              to =  "off";
              platform =  "state";
              entity_id = "binary_sensor.outdoor_noise";
            }
          ];
          condition =  {
            condition =  "time";
            after = "22:30:00";  # TODO 22
            before = "6:50:00";
          };
          action =  [
            {
              service =  "script.open_window";
            }
          ];
        }
        {
          id =  "tierspital_window_close_automation";
          alias =  "Close window in the night before asswhole tierspital starts making noise";
          trigger =  [
            {
              at =  "6:35";
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
              at =  "9:00";
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
      "automation ui" = "!include automations.yaml";
      };


      switch = [{
        platform = "rpi_gpio";
        ports = {
          # "18" = "window_motor_enabled";
          # "15" = "window_pin_1";
          # "14" = "window_pin_2";
          # "23" = "ceiling_led_pin";
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
        time_zone = "Europe/Vienna"; 
        latitude = 48.23057;
        longitude = 16.35309;
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
}
