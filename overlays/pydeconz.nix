{ buildPythonPackage, fetchPypi, aiohttp }:
buildPythonPackage rec {
  pname = "pydeconz";
  version = "69";
  # name = "${pname}-${version}";
  propagatedBuildInputs = [ aiohttp ];
  doCheck = false;
  src = fetchPypi {
    inherit pname version;
    sha256 = "4be8fe60ba2c484c041d8b675c9b5c2a037406f1c3ea075b0fe49609d60579ee";
  };
}
