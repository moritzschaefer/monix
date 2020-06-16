self: super:
# Within the overlay we use a recursive set, though I think we can use `self` as well.
rec {
  # nix-shell -p python.pkgs.my_stuff
  python = super.python.override {
    # Careful, we're using a different self and super here!
    packageOverrides = self: super: {
      pydeconz = super.buildPythonPackage rec {
        pname = "pydeconz";
        version = "71";
        # name = "${pname}-${version}";
        propagatedBuildInputs = [ super.aiohttp ];
        src = super.fetchPypi {
          inherit pname version;
          sha256 = "cd7436779296ab259c1e3e02d639a5d6aa7eca300afb03bb5553a787b27e324c";
        };
      };
    };
  };
  # nix-shell -p pythonPackages.my_stuff
  pythonPackages = python.pkgs;
}

