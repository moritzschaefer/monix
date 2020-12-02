{ buildPythonPackage, fetchPypi }:
buildPythonPackage rec {
  pname = "python-nmap";
  version = "0.6.1";
  # name = "${pname}-${version}";
  propagatedBuildInputs = [ ];
  doCheck = false;
  src = fetchPypi {
    inherit pname version;
    sha256 = "80ba0eb10a52283a54a633f40b5baa9c2ff08675d6621dd089ead942852f5bd3";
  };
}
