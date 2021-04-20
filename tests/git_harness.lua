local git_worktree = require('git-worktree')

local M = {}

local prepare_origin_repo = function(dir)
    vim.api.nvim_exec('!cp -r tests/repo_origin/ /tmp/' .. dir, true)
    vim.api.nvim_exec('!mv /tmp/'..dir..'/.git-orig /tmp/'..dir..'/.git', true)
end

local prepare_bare_repo = function(dir, origin_dir)
    vim.api.nvim_exec('!git clone --bare /tmp/'..origin_dir..' /tmp/'..dir, true)
end

local change_dir = function(dir)
    vim.api.nvim_set_current_dir('/tmp/'..dir)
    git_worktree.set_worktree_root('/tmp/'..dir)
end

local cleanup_repo = function(dir)
    vim.api.nvim_exec('silent !rm -rf /tmp/' .. dir, true)
end

local create_worktree = function(folder_path, commitish)
    vim.api.nvim_exec('!git worktree add ' .. folder_path .. ' ' .. commitish, true)
end

local project_dir = vim.api.nvim_exec('pwd', true)

local reset_cwd = function()
    vim.cmd('cd ' .. project_dir)
    vim.api.nvim_set_current_dir(project_dir)
end

local config_git_worktree = function()
    git_worktree.setup({
        update_on_change = false
    })
end

function M.in_bare_repo_from_origin_no_worktrees(cb)
    return function()
        local origin_repo_dir = 'git_worktree_test_origin_repo'
        local bare_repo_dir = 'git_worktree_test_repo'

        config_git_worktree()

        prepare_origin_repo(origin_repo_dir)
        prepare_bare_repo(bare_repo_dir, origin_repo_dir)

        change_dir(bare_repo_dir)

        local _, err = pcall(cb)

        reset_cwd()

        cleanup_repo(origin_repo_dir)
        cleanup_repo(bare_repo_dir)

        if err ~= nil then
            error(err)
        end

    end
end

function M.in_bare_repo_from_origin_1_worktree(cb)
    return function()
        local origin_repo_dir = 'git_worktree_test_origin_repo'
        local bare_repo_dir = 'git_worktree_test_repo'

        config_git_worktree()

        prepare_origin_repo(origin_repo_dir)
        prepare_bare_repo(bare_repo_dir, origin_repo_dir)
        change_dir(bare_repo_dir)
        create_worktree('master','master')

        local _, err = pcall(cb)

        reset_cwd()

        cleanup_repo(origin_repo_dir)
        cleanup_repo(bare_repo_dir)

        if err ~= nil then
            error(err)
        end

    end
end

return M
