{
  description = "Chaotic 4.0 flake ❄️";

  inputs = {
    # Devshell to set up a development environment
    devshell.url = "github:numtide/devshell";
    devshell.flake = false;

    # Common used input of our flake inputs
    flake-utils.url = "github:numtide/flake-utils";

    # The single source of truth
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Easy linting of the flake and all kind of other stuff
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks.inputs.flake-utils.follows = "flake-utils";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";
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
                devshell.name = "chaotic";
                commands = [
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
                devshell.startup = {
                  preCommitHooks.text = self.checks.${system}.pre-commit-check.shellHook;
                  chaoticEnv.text = ''
                    export LC_ALL="C.UTF-8"
                    export NIX_PATH=nixpkgs=${nixpkgs}
                  '';
                };
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
