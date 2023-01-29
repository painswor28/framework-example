{...}: {
  perSystem = {
    inputs',
    pkgs,
    final,
    ...
  }: {
    overlayAttrs = {
      framework-example = with pkgs.python3Packages; toPythonApplication framework-example;

      pythonPackagesExtensions =
        pkgs.pythonPackagesExtensions
        ++ [
          (pself: pprev: {
            torch = pprev.torch.override {
              cudaSupport = true;
            };

            framework-example = pself.callPackage ./framework-example/package.nix {
              dvc = inputs'.nd-crane.packages.dvc-with-remotes;
            };
          })
        ];
    };

    packages.framework-example = final.framework-example;
    devShells.framework-example = final.callPackage ./framework-example/shell.nix {
      python = final.python3;
      pkgs = final;
    };
  };
}
