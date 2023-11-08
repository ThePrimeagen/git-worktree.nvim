{
  stable ? true,
  self,
  system,
  neodev-plugin,
  neovim,
  neovim-nightly,
  pre-commit-hooks,
  telescope-plugin,
}: let
  mkTypeCheck = {
    nvim-api ? [],
    disabled-diagnostics ? [],
  }:
    pre-commit-hooks.lib.${system}.run {
      src = self;
      hooks = {
        lua-ls.enable = true;
      };
      settings = {
        lua-ls = {
          config = {
            runtime.version = "LuaJIT";
            Lua = {
              workspace = {
                library =
                  nvim-api
                  ++ [
                    "${telescope-plugin}/lua"
                  ];
                checkThirdParty = false;
                ignoreDir = [
                  ".git"
                  ".github"
                  ".direnv"
                  "result"
                  "nix"
                  "doc"
                  "spec" # FIXME: Add busted library
                ];
              };
              diagnostics = {
                libraryFiles = "Disable";
                disable = disabled-diagnostics;
              };
            };
          };
        };
      };
    };
in
  mkTypeCheck {
    nvim-api =
      if stable
      then [
        "${neovim}/share/nvim/runtime/lua"
        "${neodev-plugin}/types/stable"
      ]
      else [
        "${neovim-nightly}/share/nvim/runtime/lua"
        "${neodev-plugin}/types/nightly"
      ];
    disabled-diagnostics = [
      "undefined-doc-name"
      "redundant-parameter"
      "invisible"
    ];
  }
