{
  description = "Chaotic 4.0 flake ❄️";

  inputs = {
    # Chaotic Nyx (binary cache)
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

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

    # Common used input of our flake inputs
    flake-utils.follows = "chaotic/flake-utils";

    # The single source of truth
    nixpkgs.follows = "chaotic/nixpkgs";

    # Easy linting for PKGBUILDs and other things inside the devshell
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        flake-utils.follows = "chaotic/flake-utils";
        nixpkgs.follows = "chaotic/nixpkgs";
        nixpkgs-stable.follows = "chaotic/nixpkgs";
        flake-compat.follows = "chaotic/flake-compat";
      };
    };
  };
  outputs =
    { devshell
    , flake-parts
    , nixpkgs
    , pre-commit-hooks
    , self
    , ...
    } @ inp:
    let
      inputs = inp;

      perSystem =
        { pkgs
        , system
        , ...
        }: {
          checks.pre-commit-check = pre-commit-hooks.lib.${system}.run {
            hooks = {
              actionlint.enable = true;
              commitizen.enable = true;
              editorconfig-checker.enable = true;
              markdownlint.enable = true;
              nixpkgs-fmt.enable = true;
              pkgbuilds-shellcheck = {
                enable = true;
                name = "PKGBUILD shellcheck";
                # Just inform about potential issues, fixing everything up
                # will likely be impossible
                entry = "${pkgs.shellcheck}/bin/shellcheck || true";
                files = "(PKGBUILD|install$)";
                types = [ "text" ];
                language = "system";
              };
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
              cpb = pkgs.callPackage "${inp.chaotic-portable-builder}/nix/default.nix" { };
              makeDevshell = import "${inp.devshell}/modules" pkgs;
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
                  motd = ''
                    Welcome to Chaotic-AUR's maintenance devshell! 🎉
                  '';
                  name = "chaotic";
                  packages = [
                    cpb
                    pkgs.fuse-overlayfs
                    pkgs.podman
                    pkgs.skopeo
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
                    help = "Chaotic Portable Builder for local builds";
                    name = "cpb";
                    package = cpb;
                  }
                  { package = "actionlint"; }
                  { package = "commitizen"; }
                  { package = "editorconfig-checker"; }
                  { package = "markdownlint-cli"; }
                  { package = "nixpkgs-fmt"; }
                  { package = "nodePackages.prettier"; }
                  { package = "pre-commit"; }
                  { package = "shellcheck"; }
                  { package = "shfmt"; }
                  { package = "yamllint"; }
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
