{ buildPythonPackage, fetchPypi, aiohttp }:
buildPythonPackage rec {
  pname = "pydeconz";
  version = "81";
  # name = "${pname}-${version}";
  propagatedBuildInputs = [ aiohttp ];
  doCheck = false;
  src = fetchPypi {
    inherit pname version;
    sha256 = "928ec5e8296af6c5969b92118acaebae6619051f6a5e27a056871daffbf04ce2";
  };
}
