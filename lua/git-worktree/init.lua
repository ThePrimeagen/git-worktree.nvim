local Job = require("plenary.job")
local Path = require("plenary.path")

local M = {}
local root = vim.loop.cwd()
local on_change_callbacks = {}

local function change_dirs(path)
    local worktree_path = M.get_worktree_path(path)

    -- vim.loop.chdir(worktree_path)
    local cmd = string.format("cd %s", worktree_path)
    vim.cmd(cmd)
end

local function create_worktree_job(path, found_branch)

    local config = {
        'git', 'worktree', 'add',
    }

    if not found_branch then
        table.insert(config, '-b')
    end

    table.insert(config, path)
    table.insert(config, path)
    config.cwd = root

    return Job:new(config)
end

-- A lot of this could be cleaned up if there was better job -> job -> function
-- communication.  That should be doable here in the near future
local function has_worktree(path, cb)
    local found = false
    local job = Job:new({
        'git', 'worktree', 'list', on_stdout = function(_, data)
            local start = string.find(data, string.format("[%s]", path), 1, true)

            -- TODO: This is clearly a hack
            local start_with_head = string.find(data, string.format("[heads/%s]", path), 1, true)
            found = found or start or start_with_head
        end,
        cwd = root
    })

    job:after(function()
        cb(found)
    end)
    job:start()
end

local function has_branch(path, cb)
    local found = false
    local job = Job:new({
        'git', 'branch', on_stdout = function(_, data)
            data = vim.trim(data)
            found = found or data == path
        end,
        cwd = root
    })

    job:after(function()
        cb(found)
    end):start()
end

local function create_worktree(path, upstream, found_branch)
    local create = create_worktree_job(path, found_branch)
    local worktree_path = Path:new(root, path):absolute()

    local fetch = Job:new({
        'git', 'fetch', '--all',
        cwd = worktree_path,
    })

    local set_branch = Job:new({
        'git', 'branch', '-u', upstream,
        cwd = worktree_path,
    })

    local rebase = Job:new({
        'git', 'rebase',
        cwd = worktree_path,
    })

    create:and_then_on_success(fetch)
    fetch:and_then_on_success(set_branch)
    set_branch:and_then_on_success(rebase)

    local function failure(e)
        error(string.format(
            "Unable to create_worktree: RES %s, ERR %s",
            vim.inspect(e:result()),
            vim.inspect(e:stderr_result())))
    end

    rebase:after_success(function()

        vim.schedule(function()
            for idx = 1, #on_change_callbacks do
                on_change_callbacks[idx]("create", path, upstream)
            end
            M.switch_worktree(path)
        end)

    end)

    create:after_failure(failure)
    fetch:after_failure(failure)
    set_branch:after_failure(failure)
    rebase:after_failure(failure)

    create:start()
end

M.create_worktree = function(path, upstream)

    has_worktree(path, function(found)
        if found then
            error("worktree already exists")
        end

        has_branch(path, function(found_branch)
            create_worktree(path, upstream, found_branch)
        end)
    end)

end

M.switch_worktree = function(path)
    has_worktree(path, function(found)

        if not found then
            error("worktree does not exists, please create it first")
        end

        vim.schedule(function()
            change_dirs(path)
            for idx = 1, #on_change_callbacks do
                on_change_callbacks[idx]("switch", path)
            end
        end)
    end)
end

M.set_worktree_root = function(wd)
    root = wd
end

M.on_tree_change = function(cb)
    table.insert(on_change_callbacks, cb)
end

M.reload = function()
    -- todo: this is clearly a bad idea
    local local_root = root
    require("plenary.reload").reload_module("git-worktree")
    require("git-worktree").set_worktree_root(local_root)
end

M.get_root = function()
    return root
end

M.get_worktree_path = function(path)
    return Path:new(root, path):absolute()
end

return M


