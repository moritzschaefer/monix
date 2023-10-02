let
  myPythonOverride = {
    packageOverrides = self: super: rec {
      pydeconz = self.callPackage ./pydeconz.nix {};
      rpi-gpio = self.callPackage ./rpi-gpio.nix {};
      python-nmap = self.callPackage ./python-nmap.nix {};
      # pyflakes = self.callPackage ./pyflakes.nix {};
      # uvloop = self.callPackage ./uvloop.nix {};
      uvicorn = super.uvicorn.overrideAttrs (oldAttrs: {
        propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [ self.setuptools ];
        checkPhase = "";
	doCheck = false;
	doInstallCheck = false;
      });
      pproxy = super.pproxy.overrideAttrs (oldAttrs: {
        propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [ self.setuptools ];
      });
      uvloop = super.uvloop.overrideAttrs (oldAttrs: {
        pytestFlagsArray = oldAttrs.pytestFlagsArray ++ [ "--ignore=tests/test_sockets.py" "--ignore=tests/test_signals.py" "--ignore=tests/test_regr1.py" ];
        checkPhase = "";
	doCheck = false;
	doInstallCheck = false;
        });
    };
  };
in
self: super: rec {

  # https://discourse.nixos.org/t/how-to-add-custom-python-package/536/4
  # python = super.python.override myPythonOverride;
  # python2 = super.python2.override myPythonOverride;
  python3 = super.python3.override myPythonOverride;
  python37 = super.python37.override myPythonOverride;
  python38 = super.python38.override myPythonOverride;
  python39 = super.python39.override myPythonOverride;

  #pythonPackages = python.pkgs;
  # python2Packages = python.pkgs;
  python3Packages = python3.pkgs;
  python37Packages = python37.pkgs;
  python38Packages = python38.pkgs;
  python39Packages = python39.pkgs;
}
