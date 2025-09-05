{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    haskell-flake.url = "github:srid/haskell-flake";
    # nix-hs-plan.url = "github:bglgwyng/nix-hs-plan";
    nix-hs-plan.url = "path:/home/bglgwyng/Documents/GitHub/nix-hs-plan";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      debug = true;
      imports = [
        # To import a flake module
        # 1. Add foo to inputs
        # 2. Add foo as a parameter to the outputs function
        # 3. Add here: foo.flakeModule
        inputs.haskell-flake.flakeModule
      ];
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let haskellPackages = pkgs.haskell.packages.ghc9101; in
        {
          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.

          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowBroken = true;
            overlays = [
              (_: _: {
                testu01 = null;
              })
            ];
          };

          devShells.default = pkgs.mkShell {
            packages =
              let
                hpkgs = (inputs.nix-hs-plan.packages-from-plan-json {
                  inherit pkgs haskellPackages;
                  plan-json = builtins.fromJSON (builtins.readFile ./plans/plan-${pkgs.system}.json);
                });
              in
              [ (haskellPackages.ghcWithPackages (_: builtins.attrValues hpkgs)) ];
          };
          apps.generate-plan-json =
            {
              type = "app";
              program = inputs.nix-hs-plan.generate-plan-json { inherit pkgs haskellPackages; };
            };

        };
    };
}
