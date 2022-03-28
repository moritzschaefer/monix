{ buildPythonPackage, fetchPypi, aiohttp }:
buildPythonPackage rec {
  pname = "pydeconz";
  version = "87";
  # name = "${pname}-${version}";
  propagatedBuildInputs = [ aiohttp ];
  doCheck = false;
  src = fetchPypi {
    inherit pname version;
    sha256 = "71169929ab62db45a4d515ae9b46179f8a14e182fe3ce8dd698eff9c68a6bde7";
  };
}
