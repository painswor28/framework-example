{
  description = "Description for the project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nd-crane = {
      url = "github:nd-crane/nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    flake-parts,
    nd-crane,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        ./.nix
        flake-parts.flakeModules.easyOverlay
      ];
      systems = ["x86_64-linux" "aarch64-darwin"];
      perSystem = {
        lib,
        self',
        pkgs,
        system,
        ...
      }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg:
            builtins.elem (lib.getName pkg) [
              "cudatoolkit"
              "cudatoolkit-11-cudnn"
              "libcublas"
            ];
        };

        formatter = pkgs.alejandra;

        packages.default = self'.packages.framework-example;
        devShells.default = self'.devShells.framework-example;
      };
    };
}
