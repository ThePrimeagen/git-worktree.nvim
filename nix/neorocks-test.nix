{
  curl,
  extraPkgs ? [],
  git,
  name,
  neorocksTest,
  nvim,
  plenary-plugin,
  self,
  wrapNeovim,
}: let
  nvim-wrapped = wrapNeovim nvim {
    configure = {
      packages.myVimPackage = {
        start = [
          plenary-plugin
        ];
      };
    };
  };
in
  neorocksTest {
    inherit name;
    pname = "git-worktree.nvim";
    src = self;
    neovim = nvim-wrapped;

    extraPackages =
      [
        git
        curl
      ]
      ++ extraPkgs;
    luaPackages = ps:
      with ps; [
        # LuaRocks dependencies must be added here.
        plenary-nvim
      ];

    preCheck = ''
      # Neovim expects to be able to create log files, etc.
      export HOME=$(realpath .)
    '';
  }
