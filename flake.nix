{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    haskell-flake.url = "github:srid/haskell-flake";
    nix-hs-plan.url = "github:bglgwyng/nix-hs-plan";
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

          # Unwrapped GHC without extra packages
          haskellProjects.default =
            {
              projectRoot = ./.;
              basePackages = pkgs.haskellPackages;
              packages = (inputs.nix-hs-plan.packages-from-plan-json {
                inherit pkgs;
                plan-json = builtins.fromJSON (builtins.readFile ./plans/plan-${system}.json);
              });
              defaults.settings.all = {
                check = false;
              };
              devShell = {
                hlsCheck.enable = false;
                tools =
                  _: with config.haskellProjects.default.basePackages; {
                    cabal-install = cabal-install;
                    ghcid = ghcid;
                    hlint = hlint;
                    haskell-language-server = haskell-language-server;
                  };
                hoogle = false;
              };
            };
        };
    };
}
