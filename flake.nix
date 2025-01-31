{
  description = "Chaotic 4.0 flake ❄️";

  inputs = {
    # Chaotic Nyx (binary cache)
    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
      inputs.fenix.follows = "";
      inputs.jovian.follows = "";
    };

    # Local debug builds using infra 4.0 code
    chaotic-portable-builder = {
      owner = "garuda-linux";
      repo = "tools%2Fchaotic-portable-builder";
      type = "gitlab";
      flake = false;
    };

    # Devshell to set up a development environment
    devshell = {
      url = "github:numtide/devshell";
      flake = false;
    };

    # Flake parts
    flake-parts.url = "github:hercules-ci/flake-parts";

    # The single source of truth
    nixpkgs.follows = "chaotic/nixpkgs";

    # Easy linting for PKGBUILDs and other things inside the devshell
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "chaotic/nixpkgs";
    };
  };
  outputs =
    { flake-parts
    , nixpkgs
    , pre-commit-hooks
    , self
    , ...
    } @ inputs:
    let
      perSystem =
        { pkgs
        , system
        , ...
        }: {
          checks.pre-commit-check = pre-commit-hooks.lib.${system}.run {
            hooks = {
              actionlint.enable = true;
              commitizen.enable = true;
              markdownlint.enable = true;
              nixpkgs-fmt.enable = true;
              pkgbuilds-formatting = {
                enable = true;
                name = "PKGBUILD shfmt";
                entry = "${pkgs.shfmt}/bin/shfmt -d -w";
                files = "(PKGBUILD|install$)";
                types = [ "text" ];
                language = "system";
              };
              prettier.enable = true;
              yamllint.enable = true;
            };
            src = ./.;
          };

          devShells =
            let
              chaotic = builtins.readFile ./.tools/chaotic.sh;
              cpb = pkgs.callPackage "${inputs.chaotic-portable-builder}/nix/default.nix" { };
              makeDevshell = import "${inputs.devshell}/modules" pkgs;
              mkShell = config:
                (makeDevshell {
                  configuration = {
                    inherit config;
                    imports = [ ];
                  };
                }).shell;
            in
            rec {
              default = chaotic-shell;
              chaotic-shell = mkShell {
                devshell = {
                  name = "chaotic-devshell";
                  packages = with pkgs; [
                    fuse-overlayfs
                    jq
                    podman
                    skopeo
                  ];
                  startup = {
                    preCommitHooks.text = self.checks.${system}.pre-commit-check.shellHook;
                    chaoticEnv.text = ''
                      export LC_ALL="C.UTF-8"
                      export NIX_PATH=nixpkgs=${nixpkgs}

                      if [ ! -f /etc/containers/policy.json ] && [ ! -f ~/.config/containers/policy.json ]; then
                        echo "No podman policy.json found. Installing default to home folder."
                        install -Dm755 ${pkgs.skopeo.src}/default-policy.json ~/.config/containers/policy.json
                      fi

                      if [ ! -d ./pkgbuilds ]; then
                        echo "No pkgbuilds folder found. Symlinking this directory to ./pkgbuilds."
                        ln -s ./ ./pkgbuilds
                      fi
                    '';
                  };
                };
                commands = [
                  {
                    help = "Helper script for maintaining packages";
                    name = "chaotic";
                    command = chaotic;
                    category = "Chaotic tools";
                  }
                  {
                    help = "Chaotic Portable Builder for local builds";
                    name = "cpb";
                    package = cpb;
                    category = "Chaotic tools";
                  }
                  {
                    package = "actionlint";
                    category = "Linters";
                  }
                  {
                    package = "commitizen";
                    category = "Linters";
                  }
                  {
                    package = "editorconfig-checker";
                    category = "Linters";
                  }
                  {
                    package = "markdownlint-cli";
                    category = "Linters";
                  }
                  {
                    package = "nixpkgs-fmt";
                    category = "Formatters";
                  }
                  {
                    package = "nodePackages_latest.prettier";
                    category = "Formatters";
                  }
                  {
                    package = "pre-commit";
                    category = "Linters";
                  }
                  {
                    name = "shellcheck";
                    package = "shellcheck";
                    category = "Linters";
                  }
                  {
                    package = "shfmt";
                    category = "Formatters";
                  }
                  {
                    package = "yamllint";
                    category = "Linters";
                  }
                ];
              };
            };

          formatter = pkgs.nixpkgs-fmt;
        };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Flake modules
      imports = [ inputs.pre-commit-hooks.flakeModule ];

      # The available systems
      systems = [ "x86_64-linux" "aarch64-linux" ];

      # This applies to all systems
      inherit perSystem;
    };
}
