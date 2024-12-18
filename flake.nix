{
  description = "DeltaQ for Jupyter and Docker";

  nixConfig.extra-substituters = [
    "https://tweag-jupyter.cachix.org"
  ];
  nixConfig.extra-trusted-public-keys = [
    "tweag-jupyter.cachix.org-1:UtNH4Zs6hVUFpFBTLaA4ejYavPo5EFFqgd7G7FxGW9g="
  ];

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    jupyenv.url = "github:tweag/jupyenv?ref=0c86802aaa3ffd3e48c6f0e7403031c9168a8be2";
    deltaq = {
      url = "path:/extra/iohk/dq-revamp/lib/deltaq";
      flake = false;
    };
    probability-polynomial = {
      url = "path:/extra/iohk/dq-revamp/lib/probability-polynomial";
      flake = false;
    };
  };

  outputs = {
    self,
    flake-compat,
    flake-utils,
    nixpkgs,
    jupyenv,
    deltaq,
    probability-polynomial,
    ...
  } @ inputs:
    flake-utils.lib.eachSystem [ flake-utils.lib.system.x86_64-linux ]
    (
      system: let

        overlay = next: prev: {
          haskell = prev.haskell // {
            packageOverrides = hnext: hprev: {
              # Include the DeltaQ packages.
              deltaq = hprev.callCabal2nixWithOptions "deltaq" deltaq "--no-check" {};
              probability-polynomial = hprev.callCabal2nixWithOptions "probability-polynomial" probability-polynomial "--no-check" {};
              # Sadly, we need to loosen the dependency constraint that `Chart-cairo` has on `time`.
              Chart-cairo = hprev.callPackage (
                { mkDerivation, array, base, cairo, Chart, colour
                , data-default-class, lens, lib, mtl, old-locale, operational, time
                }:
                mkDerivation {
                  pname = "Chart-cairo";
                  version = "1.9.4.1";
                  sha256 = "27cbc2f1237b739eb60c6c470a9324b7ab63974f33116411ea4c2f347ca22074";
                  prePatch = ''
                    sed -e '/, time/s/ >=.*$//' -i Chart-cairo.cabal
                  '';
                  libraryHaskellDepends = [
                    array base cairo Chart colour data-default-class lens mtl
                    old-locale operational time
                  ];
                  homepage = "https://github.com/timbod7/haskell-chart/wiki";
                  description = "Cairo backend for Charts";
                  license = lib.licenses.bsd3;
                }
              ) {};
            };
          };
        };

        pkgs = import nixpkgs { inherit system; overlays = [ overlay ]; };

        inherit (jupyenv.lib.${system}) mkJupyterlabNew;

        jupyterlab = mkJupyterlabNew ({...}: {
          nixpkgs = nixpkgs;
          imports = [(import ./kernels.nix {pkgs = pkgs;})];
        });

        docker = pkgs.dockerTools.buildImage {
          name = "jupyter-deltaq";
          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = [
              pkgs.dockerTools.usrBinEnv
              pkgs.dockerTools.binSh
              pkgs.bash
              pkgs.coreutils
              pkgs.nodejs_18
              jupyterlab
            ];
            pathsToLink = [ "/bin" ];
          };
          runAsRoot = ''
            #!${pkgs.runtimeShell}
            ${pkgs.dockerTools.shadowSetup}
            groupadd -r deltaq
            useradd -r -g deltaq deltaq
            mkdir -p home/deltaq/examples
            chown -R deltaq:deltaq home/deltaq
            mkdir -p /usr/bin
            ln -s /bin/env /usr/bin/env
          '';
          extraCommands =
            let
              example1 = builtins.readFile "${self}/examples/01 - Introduction.ipynb";
              example2 = builtins.readFile "${self}/examples/02 - Visualisations.ipynb";
            in ''
              #!${pkgs.runtimeShell}
              chmod 0777 tmp
              mkdir -p home/deltaq/examples
              cp -r ${self}/examples home/deltaq/
            '';
          config = {
            User = "deltaq";
            WorkingDir = "/home/deltaq";
            Cmd = [
              "${jupyterlab}/bin/jupyter-lab"
              "--no-browser"
              "--ip=0.0.0.0"
              "--port=8888"
              "--NotebookApp.token=deltaq"
            ];
            ExposedPorts = {
              "8888" = {};
            };
          };
        };

      in rec {
        packages = {inherit jupyterlab docker;};
        packages.default = jupyterlab;
        apps.default.program = "${jupyterlab}/bin/jupyter-lab";
        apps.default.type = "app";
      }

    );

}
