{
  description = "Chaotic 4.0 flake ❄️";

  inputs = {
    # Local debug builds using infra 4.0 code
    chaotic-portable-builder = {
      owner = "garuda-linux";
      repo = "tools%2Fchaotic-portable-builder";
      type = "gitlab";
      flake = false;
    };

    # The single source of truth
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Easy linting for PKGBUILDs and other things inside the devshell
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forAllSystems =
        f:
        lib.genAttrs systems (
          system:
          let
            pkgs = import nixpkgs { inherit system; };
          in
          f (pkgs // { inherit system; })
        );

      mkPreCommitCheck =
        pkgs:
        inputs.pre-commit-hooks.lib.${pkgs.stdenv.hostPlatform.system}.run {
          package = pkgs.prek;
          hooks = {
            commitizen.enable = true;
            nixfmt.enable = true;
            pkgbuilds-formatting = {
              enable = true;
              name = "PKGBUILD shfmt";
              entry = "${pkgs.shfmt}/bin/shfmt -d -w";
              files = "^PKGBUILD$";
              types = [ "text" ];
              language = "system";
            };
            prettier.enable = true;
          };
          src = ./.;
        };
    in
    {
      checks = forAllSystems (pkgs: {
        pre-commit-check = mkPreCommitCheck pkgs;
      });

      devShells = forAllSystems (
        {
          pkgs,
          system,
          ...
        }:
        let
          chaotic = pkgs.writeShellScriptBin "chaotic" (builtins.readFile ./.tools/chaotic.sh);
          cpb = pkgs.callPackage "${inputs.chaotic-portable-builder}/nix/default.nix" { };
          isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

          tools = [
            "chaotic"
            "nixfmt"
            "prek"
            "prettier"
            "shellcheck"
            "shfmt"
          ]
          ++ lib.optional (!isDarwin) "cpb";

          deps = [
            "aria2"
            "getoptions"
            "jq"
            "podman"
            "skopeo"
            "trash-cli"
          ]
          ++ lib.optional (!isDarwin) "fuse-overlayfs";
        in
        {
          default = pkgs.mkShell {
            name = "chaotic-devshell";

            packages =
              with pkgs;
              [
                aria2
                chaotic
                getoptions
                jq
                nixfmt
                podman
                prek
                prettier
                shellcheck
                shfmt
                skopeo
                trash-cli
              ]
              ++ lib.optional (!isDarwin) cpb
              ++ lib.optional (!isDarwin) fuse-overlayfs;

            shellHook = ''
              ${self.checks.${system}.pre-commit-check.shellHook}

              printf '\033[1;35mChaotic 4.0 devshell\033[0m ❄️\n'
              printf '  \033[2mtools:\033[0m %s\n' "${lib.concatStringsSep " " tools}"
              printf '  \033[2mdeps: \033[0m %s\n' "${lib.concatStringsSep " " deps}"

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
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixpkgs-fmt);
    };
}
