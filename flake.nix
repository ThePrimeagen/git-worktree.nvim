{
  description = "git-worktree.nvim - supercharge your haskell experience in neovim";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    neorocks. url = "github:nvim-neorocks/neorocks";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neodev-nvim = {
      url = "github:folke/neodev.nvim";
      flake = false;
    };
    plenary-nvim = {
      url = "github:nvim-lua/plenary.nvim";
      flake = false;
    };
    telescope-nvim = {
      url = "github:nvim-telescope/telescope.nvim";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      perSystem = {
        config,
        pkgs,
        system,
        inputs',
        ...
      }: let
        pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
          src = self;
          hooks = {
            alejandra.enable = true;
            #stylua.enable = true;
            #luacheck.enable = true;
            #markdownlint.enable = true;
          };
        };
      in {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            inputs.neorocks.overlays.default
          ];
        };
        devShells = {
          default = pkgs.mkShell {
            name = "haskell-tools.nvim-shell";
            inherit (pre-commit-check) shellHook;
            buildInputs =
              (with pkgs; [
                neorocks
                haskellPackages.neolua-bin
              ])
              ++ (with inputs.pre-commit-hooks.packages.${system}; [
                alejandra
                #lua-language-server
                #stylua
                #luacheck
                #markdownlint-cli
              ]);
          };
        };

        packages.neodev-plugin = pkgs.vimUtils.buildVimPlugin {
          name = "neodev.nvim";
          src = inputs.neodev-nvim;
        };
        packages.plenary-plugin = pkgs.vimUtils.buildVimPlugin {
          name = "plenary.nvim";
          src = inputs.plenary-nvim;
        };
        packages.telescope-plugin = pkgs.vimUtils.buildVimPlugin {
          name = "telescope.nvim";
          src = inputs.telescope-nvim;
        };
        packages.neorocks-test-stable = pkgs.callPackage ./nix/neorocks-test.nix {
          name = "git-worktree-stable";
          inherit self;
          nvim = pkgs.neovim-unwrapped;
          inherit (config.packages) plenary-plugin;
        };

        checks = {
          inherit pre-commit-check;
          # type-check-stable = pkgs.callPackage ./nix/type-check.nix {
          #   stable = true;
          #   inherit (config.packages) neodev-plugin telescope-plugin;
          #   inherit (inputs) pre-commit-hooks;
          #   inherit self;
          # };
          # type-check-nightly = pkgs.callPackage ./nix/type-check.nix {
          #   stable = false;
          #   inherit (config.packages) neodev-plugin telescope-plugin;
          #   inherit (inputs) pre-commit-hooks;
          #   inherit self;
          # };
          neorocks-test-stable = pkgs.callPackage ./nix/neorocks-test.nix {
            name = "git-worktree-stable";
            inherit self;
            nvim = pkgs.neovim-unwrapped;
            inherit (config.packages) plenary-plugin;
          };
          neorocks-test-unstable = pkgs.callPackage ./nix/neorocks-test.nix {
            name = "git-worktree-nightly";
            inherit self;
            nvim = pkgs.neovim-nightly;
            inherit (config.packages) plenary-plugin;
          };
        };
      };
    };
}
