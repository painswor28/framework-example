{
  lib,
  buildPythonPackage,
  isPy3k,
  pdm-pep517,
  dvc,
  torch,
  torchvision,
}:
buildPythonPackage rec {
  pname = "framework-example";
  version = "0.0.1";
  format = "pyproject";
  disabled = !isPy3k;

  src = ../../.;

  buildInputs = [
    pdm-pep517
  ];

  propagatedBuildInputs = [
    torch
    torchvision
    dvc
  ];

  passthru = {
    optional-dependencies = {
      testing = [];
    };
  };

  meta = with lib; {
    homepage = "";
    maintainers = with maintainers; [];
  };
}
