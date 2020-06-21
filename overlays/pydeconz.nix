{ buildPythonPackage, fetchPypi, aiohttp }:
buildPythonPackage rec {
  pname = "pydeconz";
  version = "71";
  # name = "${pname}-${version}";
  propagatedBuildInputs = [ aiohttp ];
  doCheck = false;
  src = fetchPypi {
    inherit pname version;
    sha256 = "cd7436779296ab259c1e3e02d639a5d6aa7eca300afb03bb5553a787b27e324c";
  };
}
