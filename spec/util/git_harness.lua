local system = require('util.system')

local M = {}

local origin_repo_path = nil

function M.setup_origin_repo()
    if origin_repo_path ~= nil then
        return origin_repo_path
    end

    local workspace_dir = system.create_temp_dir("workspace-dir")
    vim.api.nvim_set_current_dir(vim.fn.getcwd())
    system.run("cp -r spec/.repo " .. workspace_dir)
    vim.api.nvim_set_current_dir(workspace_dir)
    system.run([[
        mv .repo/.git-orig ./.git
        mv .repo/* .
        git config user.email "test@test.test"
        git config user.name "Test User"
    ]])

    origin_repo_path = system.create_temp_dir("origin-repo")
    system.run(string.format("git clone --bare %s %s", workspace_dir, origin_repo_path))

    return origin_repo_path
end

function M.prepare_repo()
    M.setup_origin_repo()

    local working_dir = system.create_temp_dir("working-dir")
    vim.api.nvim_set_current_dir(working_dir)
    system.run(string.format("git clone %s %s", origin_repo_path, working_dir))
    system.run([[
        git config remote.origin.url git@github.com:test/test.git
        git config user.email "test@test.test"
        git config user.name "Test User"
    ]])
    return working_dir
end

function M.prepare_repo_bare()
    M.setup_origin_repo()

    local working_dir = system.create_temp_dir("working-bare-dir")
    vim.api.nvim_set_current_dir(working_dir)
    system.run(string.format("git clone --bare %s %s", origin_repo_path, working_dir))
    return working_dir
end

function M.prepare_repo_worktree()
    M.setup_origin_repo()

    local working_dir = system.create_temp_dir("working-worktree-dir")
    vim.api.nvim_set_current_dir(working_dir)
    system.run(string.format("git clone --bare %s %s", origin_repo_path, working_dir))
    system.run("git worktree add wt master")
    local worktree_dir = working_dir .. "/wt"
    vim.api.nvim_set_current_dir(worktree_dir)
    return worktree_dir
end

return M
