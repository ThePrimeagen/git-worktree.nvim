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
There are a few known issues.  I'll try to be actively filing them in the issues.  If you experience something and its not an issue, feel free to make an issue!  Even if its a dupe I am just happy for the contribution.  

## Dependencies<a name="dependencies"></a>

Requires NeoVim 0.5+

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

`update_on_change`:  Updates the current buffer to point to the new work tree if
the file is found in the new project. Otherwise, it will open up `:Ex` at the
worktree root.

`clearjumps_on_change`: Every time you switch branches, your jumplist will be
cleared so that you don't accidentally go backward to a different branch and
edit the wrong files.

```lua
require("git-worktree").setup({
    update_on_change = <boolean> -- default: true,
    clearjumps_on_change = <boolean> -- default: true,
})
```

## Usage<a name="usage"></a>

Three primary functions should cover your day-to-day.

```lua
-- Creates a worktree.  Requires the branch name and the upstream
-- Example:
:lua require("git-worktree").create_worktree("feat-69", "upstream/master")

-- switches to an existing worktree.  Requires the branch name
-- Example:
:lua require("git-worktree").switch_worktree("feat-69")

-- deletes to an existing worktree.  Requires the branch name
-- Example:
:lua require("git-worktree").delete_worktree("feat-69")
```

## Telescope<a name="telescope"></a>

Add the following to your vimrc to load the telescope extension

```lua
require("telescope").load_extension("git_worktree")
```

To bring up the telescope window listing your workspaces run the following

```lua
:lua require('telescope').extensions.git_worktree.git_worktrees()
-- <Enter> - switches to that worktree
-- <c-d> - deletes that worktree
-- <c-D> - force deletes that worktree
```

## Hooks<a name="hooks"></a>

Yes!  The best part about `git-worktree` is that it emits information so that you
can act on it.

```lua
local Worktree = require("git-worktree")

-- op = "switch", "create", "delete"
-- path = branch in which was swapped too
-- upstream = only present on create, upstream of create operation
Worktree.on_tree_update(function(op, path, upstream)
end)
```

This means that you can use [harpoon](https://github.com/ThePrimeagen/harpoon)
or other plugins to perform follow up operations that will help in turbo
charging your development experience!

## Made with fury<a name="made-with-fury"></a>

All plugins are made live on [Twitch](https://twitch.tv/ThePrimeagen) with love
and fury.  Come and join!
