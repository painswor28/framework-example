{
  python,
  pkgs,
}:
pkgs.mkShell rec {
  name = "python-framework-example";

  venvDir = ".venv";

  buildInputs = [
    pkgs.pdm
  ];

  inputsFrom = [
    python.pkgs.framework-example
  ];

  shellHook = ''
    runHook preShellHook

    # Editable Python Setup
    if [ ! -d "${venvDir}" ]; then
      ${python.interpreter} -m venv "${venvDir}"
    fi

    source "${venvDir}/bin/activate"

    if [ -e pyproject.toml ]; then
      tmp_path=$(mktemp -d)
      export PATH="$tmp_path/bin:$PATH"
      export NIX_PYTHONPATH="$tmp_path/${python.sitePackages}"
      mkdir -p "$tmp_path/${python.sitePackages}"
      ${python.interpreter} -m pip install -e . --prefix "$tmp_path" --no-build-isolation >&2
    fi

    unset SOURCE_DATE_EPOCH

    # Add CUDA libraries for WSL
    [ -d "/usr/lib/wsl/lib" ] && export LD_LIBRARY_PATH="/usr/lib/wsl/lib:$LD_LIBRARY_PATH"
  '';
}
