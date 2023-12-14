# git-worktree.nvim<a name="git-worktreenvim"></a>

A simple wrapper around git worktree operations, create, switch, and delete.
There is some assumed workflow within this plugin, but pull requests are welcomed to
fix that).

<!-- mdformat-toc start --slug=github --maxlevel=6 --minlevel=1 -->

- [git-worktree.nvim](#git-worktreenvim)
  - [Known Issues](#known-issues)
  - [Dependencies](#dependencies)
  - [Getting Started](#getting-started)
  - [Setup](#setup)
  - [Repository](#repository)
  - [Options](#options)
  - [Usage](#usage)
  - [Telescope](#telescope)
  - [Hooks](#hooks)
  - [Made with fury](#made-with-fury)

<!-- mdformat-toc end -->

## Known Issues<a name="known-issues"></a>
There are a few known issues.  I'll try to be actively filing them in the issues.  If you experience something, and it's not an issue, feel free to make an issue!  Even if it's a dupe I am just happy for the contribution.

## Dependencies<a name="dependencies"></a>

Requires NeoVim 0.5+
Requires plenary.nvim
Optional telescope.nvim for telescope extension

## Getting Started<a name="getting-started"></a>

First, install the plugin the usual way you prefer.

```console
Plug 'ThePrimeagen/git-worktree.nvim'
```

Next, re-source your `vimrc`/`init.vim` and execute `PlugInstall` to ensure you have the plugin
installed.

## Setup<a name="setup"></a>

## Repository<a name="repository"></a>

This repository does work best with a bare repo.  To clone a bare repo, do the following.

```shell
git clone --bare <upstream>
```

If you do not use a bare repo, using telescope create command will be more helpful in the process of creating a branch.

### Debugging
git-worktree writes logs to a `git-worktree-nvim.log` file that resides in Neovim's cache path. (`:echo stdpath("cache")` to find where that is for you.)

By default, logging is enabled for warnings and above. This can be changed by setting `vim.g.git_worktree_log_level` variable to one of the following log levels: `trace`, `debug`, `info`, `warn`, `error`, or `fatal`. Note that this would have to be done **before** git-worktree's `setup` call. Alternatively, it can be more convenient to launch Neovim with an environment variable, e.g. `> GIT_WORKTREE_NVIM_LOG=trace nvim`. In case both, `vim.g` and an environment variable are used, the log level set by the environment variable overrules. Supplying an invalid log level defaults back to warnings.

### Troubleshooting
If the upstream is not setup correctly when trying to pull or push, make sure the following command returns what is shown below. This seems to happen with the gitHub cli.
```
git config --get remote.origin.fetch

+refs/heads/*:refs/remotes/origin/*
```
if it does not run the following
```
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
```

## Options<a name="options"></a>

`change_directory_command`: The vim command used to change to the new worktree directory.
Set this to `tcd` if you want to only change the `pwd` for the current vim Tab.

`update_on_change`:  Updates the current buffer to point to the new work tree if
the file is found in the new project. Otherwise, the following command will be run.

`update_on_change_command`: The vim command to run during the `update_on_change` event.
Note, that this command will only be run when the current file is not found in the new worktree.
This option defaults to `e .` which opens the root directory of the new worktree.

`clearjumps_on_change`: Every time you switch branches, your jumplist will be
cleared so that you don't accidentally go backward to a different branch and
edit the wrong files.

`autopush`: When creating a new worktree, it will push the branch to the upstream then perform a `git rebase`

```lua
require("git-worktree").setup({
    change_directory_command = <str> -- default: "cd",
    update_on_change = <boolean> -- default: true,
    update_on_change_command = <str> -- default: "e .",
    clearjumps_on_change = <boolean> -- default: true,
    autopush = <boolean> -- default: false,
})
```

## Usage<a name="usage"></a>

Three primary functions should cover your day-to-day.

The path can be either relative from the git root dir or absolute path to the worktree.

```lua
-- Creates a worktree.  Requires the path, branch name, and the upstream
-- Example:
:lua require("git-worktree").create_worktree("feat-69", "master", "origin")

-- switches to an existing worktree.  Requires the path name
-- Example:
:lua require("git-worktree").switch_worktree("feat-69")

-- deletes an existing worktree.  Requires the path name
-- Example:
:lua require("git-worktree").delete_worktree("feat-69")
```

## Telescope<a name="telescope"></a>

Add the following to your vimrc to load the telescope extension

```lua
require("telescope").load_extension("git_worktree")
```

### Switch and Delete a worktrees
To bring up the telescope window listing your workspaces run the following

```lua
:lua require('telescope').extensions.git_worktree.git_worktrees()
-- <Enter> - switches to that worktree
-- <c-d> - deletes that worktree
-- <c-f> - toggles forcing of the next deletion
```

### Create a worktree
To bring up the telescope window to create a new worktree run the following

```lua
:lua require('telescope').extensions.git_worktree.create_git_worktree()
```
First a telescope git branch window will appear. Pressing enter will choose the selected branch for the branch name. If no branch is selected, then the prompt will be used as the branch name.

After the git branch window, a prompt will be presented to enter the path name to write the worktree to.

As of now you can not specify the upstream in the telescope create workflow, however if it finds a branch of the same name in the origin it will use it

## Hooks<a name="hooks"></a>

Yes!  The best part about `git-worktree` is that it emits information so that you
can act on it.

```lua
local Worktree = require("git-worktree")

-- op = Operations.Switch, Operations.Create, Operations.Delete
-- metadata = table of useful values (structure dependent on op)
--      Switch
--          path = path you switched to
--          prev_path = previous worktree path
--      Create
--          path = path where worktree created
--          branch = branch name
--          upstream = upstream remote name
--      Delete
--          path = path where worktree deleted

Worktree.on_tree_change(function(op, metadata)
  if op == Worktree.Operations.Switch then
    print("Switched from " .. metadata.prev_path .. " to " .. metadata.path)
  end
end)
```

This means that you can use [harpoon](https://github.com/ThePrimeagen/harpoon)
or other plugins to perform follow up operations that will help in turbo
charging your development experience!

## Made with fury<a name="made-with-fury"></a>

All plugins are made live on [Twitch](https://twitch.tv/ThePrimeagen) with love
and fury.  Come and join!
