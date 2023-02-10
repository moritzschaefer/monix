# see https://blog.stigok.com/2019/11/05/packing-python-script-binary-nicely-in-nixos.html
# Below, we can supply defaults for the function arguments to make the script
# runnable with `nix-build` without having to supply arguments manually.
# Also, this lets me build with Python 3.7 by default, but makes it easy
# to change the python version for customised builds (e.g. testing).
{ nixpkgs ? import <nixpkgs> {}, pythonPkgs ? nixpkgs.pkgs.python39Packages }:

let
  # This takes all Nix packages into this scope
  inherit (nixpkgs) pkgs;
  # This takes all Python packages from the selected version into this scope.
  inherit pythonPkgs;

  # Inject dependencies into the build function
  f = { buildPythonPackage, click, feedparser, flask, requests, feedgen }:
    buildPythonPackage rec {
      pname = "nature_filter";
      version = "0.1.3";

      # If you have your sources locally, you can specify a path
      #src = /home/stigok/src/nature_filter

      # Pull source from a Git server. Optionally select a specific `ref` (e.g. branch),
      # or `rev` revision hash.
      src = builtins.fetchGit {
        url = "https://github.com/moritzschaefer/nature_filter.git";
        ref = "main";
	rev = "79bc308caddde76ddd5ad7ae506b875079c7977b";
      };

      # Specify runtime dependencies for the package
      propagatedBuildInputs = [ click feedparser flask requests feedgen ];

      # If no `checkPhase` is specified, `python setup.py test` is executed
      # by default as long as `doCheck` is true (the default).
      # I want to run my tests in a different way:
      doCheck = false;
      checkPhase = ''
        python -m unittest tests/*.py
      '';

      # Meta information for the package
      meta = {
        description = ''
          Serve filtered nature RSS feed
        '';
      };
    };

  drv = pythonPkgs.callPackage f {};
in
  if pkgs.lib.inNixShell then drv.env else drv
