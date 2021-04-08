local Job = require("plenary.job")
local Path = require("plenary.path")

local M = {}

-- TODO: how no global friend?
git_worktree_root = git_worktree_root or vim.loop.cwd()

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
    config.cwd = git_worktree_root

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
        cwd = git_worktree_root
    })

    job:after(function()
        cb(found)
    end)
    job:start()
end

local function failure(cmd, path)
    return function(e)
        error(string.format(
        "Unable to create_worktree: PATH %s CMD %s RES %s, ERR %s",
        path,
        vim.inspect(cmd),
        vim.inspect(e:result()),
        vim.inspect(e:stderr_result())))
    end
end


local function has_branch(path, cb)
    local found = false
    local job = Job:new({
        'git', 'branch', on_stdout = function(_, data)
            data = vim.trim(data)
            found = found or data == path
        end,
        cwd = git_worktree_root
    })

    job:after(function()
        cb(found)
    end):start()
end

local function create_worktree(path, upstream, found_branch)
    local create = create_worktree_job(path, found_branch)
    local worktree_path = Path:new(git_worktree_root, path):absolute()

    local fetch = Job:new({
        'git', 'fetch', '--all',
        cwd = worktree_path,
    })

    local set_branch = Job:new({
        'git', 'branch', string.format('--set-upstream-to=%s', upstream), path,
        cwd = worktree_path,
    })

    local rebase = Job:new({
        'git', 'rebase',
        cwd = worktree_path,
    })

    create:and_then_on_success(fetch)
    fetch:and_then_on_success(set_branch)
    set_branch:and_then_on_success(rebase)

    rebase:after_success(function()

        vim.schedule(function()
            for idx = 1, #on_change_callbacks do
                on_change_callbacks[idx]("create", path, upstream)
            end
            M.switch_worktree(path)
        end)

    end)

    create:after_failure(failure(create.args, git_worktree_root))
    fetch:after_failure(failure(fetch.args, worktree_path))
    set_branch:after_failure(failure(set_branch.args, worktree_path))
    rebase:after_failure(failure(rebase.args, worktree_path))

    create:start()
end

M.create_worktree = function(path, upstream)

    if upstream == nil then
        error("Please provide an upstream...")
    end

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

M.delete_worktree = function(path)
    -- TODO: Implement

    vim.schedule(function()
        change_dirs(path)
        for idx = 1, #on_change_callbacks do
            on_change_callbacks[idx]("delete", path)
        end
    end)

end

M.set_worktree_root = function(wd)
    git_worktree_root = wd
end

M.update_current_buffer = function()
    local cwd = vim.loop.cwd()
    local current_buf_name = vim.api.nvim_buf_get_name(0)

    if not current_buf_name or current_buf_name == "" then
        return false
    end

    local name = Path:new(current_buf_name):absolute()
    local start, fin = string.find(name, cwd, 1, true)

    if start ~= nil then
        return true
    end

    start, fin = string.find(name, git_worktree_root, 1, true)
    if start == nil then
        return false
    end

    local local_name = name:sub(fin + 2)

    start, fin = string.find(local_name, Path.path.sep, 1, true)
    local_name = local_name:sub(fin + 1)

    local bufnr = vim.fn.bufnr(Path:new({cwd, local_name}):absolute() , true)
    vim.api.nvim_set_current_buf(bufnr)

    return true
end

M.on_tree_change = function(cb)
    table.insert(on_change_callbacks, cb)
end

M.reload = function()
    -- todo: this is clearly a bad idea
    local local_root = git_worktree_root
    require("plenary.reload").reload_module("git-worktree")
    require("git-worktree").set_worktree_root(local_root)
end

M.get_root = function()
    return git_worktree_root
end

M.get_worktree_path = function(path)
    return Path:new(git_worktree_root, path):absolute()
end

M.setup = function()
end

return M


