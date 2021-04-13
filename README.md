# git-worktree.nvim
----

A simple wrapper around git worktree operations, create, switch, and delete.
There is definitely some assumed work flow within this plugin (prs wanted to
fix that).

## Warning
Requires NeoVim 0.5+

## Getting Started
First, install the plugin the usual way you prefer.

```
Plug 'ThePrimeagen/git-worktree.nvim'
```

Resource your vimrc and execute `PlugInstall` to ensure you have the plugin
installed.

### Setup
#### Options
`update_on_change`: Updates the current buffer to point to the new work tree if
the file is found in the new project, else it will open up `:Ex` at the
worktree root

`clearjumps_on_change`: Everytime you switch branches, your jumplist will be
cleared so that you don't accidentally go backwards to a different branch and
edit the wrong files.

```lua
require("git-worktree").setup({
    update_on_change = <boolean> -- default: true,
    clearjumps_on_change = <boolean> -- default: true,
})
```

## Usage
There are three primary functions that should be your day to day.

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

## Hooks!
Yes!  The best part about git-worktree is that it emits information so that you
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

### Made with fury
all plugins are made live on [Twitch](https://twitch.tv/ThePrimeagen) with love
and fury.  Come and join!


