local Job = require("plenary.job")
local Path = require("plenary.path")
local Enum = require("git-worktree.enum")

local Status = require("git-worktree.status")

local status = Status:new()
local M = {}
local git_worktree_root = nil
local current_worktree_path = nil
local on_change_callbacks = {}

M._find_git_root_job = function(sync)
    sync = sync or false
    local cwd = vim.loop.cwd()

    local is_in_worktree = false

    local inside_worktree_job = Job:new({
        'git', 'rev-parse', '--is-inside-work-tree',
        cwd = cwd,
    })

    local process_inside_worktree = function(stdout, code)
        if code ~= 0 then
            git_worktree_root = nil
            return
        else
            if stdout == "true" then
                is_in_worktree = true
            end
        end
    end

    local find_git_dir_job = Job:new({
        'git', 'rev-parse', '--git-dir',
        cwd = cwd,
    })

    local process_find_git_dir = function(stdout, code)
        if is_in_worktree then
            -- if in worktree git dir returns absolute path

            -- try to find the dot git folder (non-bare repo)
            local git_dir = Path:new(stdout)
            local has_dot_git = false
            for _, dir in ipairs(git_dir:_split()) do
                if dir == ".git" then
                    has_dot_git = true
                    break
                end
            end

            if has_dot_git then
                if stdout == ".git" then
                    git_worktree_root = cwd
                else
                    local start = stdout:find("%.git")
                    git_worktree_root = stdout:sub(1,start - 2)
                end
            else
                local start = stdout:find("/worktrees/")
                git_worktree_root = stdout:sub(0, start - 1)
            end
        elseif stdout == "." then
            -- we are in the root git dir
            git_worktree_root = cwd
        else
            -- if not in worktree git dir returns relative path
            local start = stdout:find(".git")
            git_worktree_root = Path:new(
            string.format("%s" .. Path.path.sep .. "%s", cwd, stdout:sub(1,start))
            )
        end
    end

    local find_toplevel_job = Job:new({
        'git', 'rev-parse', '--show-toplevel',
        cwd = cwd,
    })

    local process_find_toplevel = function(stdout, code)
        current_worktree_path = stdout
    end


    local stdout, code = inside_worktree_job:sync()
    if code ~= 0 then
        -- not in a git dir
        git_worktree_root = nil
        current_worktree_path = nil
        return
    end
    stdout = table.concat(stdout, "")
    process_inside_worktree(stdout, code)

    stdout, code = find_git_dir_job:sync()
    stdout = table.concat(stdout, "")
    process_find_git_dir(stdout, code)

    stdout, code = find_toplevel_job:sync()
    if code ~= 0 then
        current_worktree_path = nil
        return
    end
    stdout = table.concat(stdout, "")
    process_find_toplevel(stdout, code)

end

M._find_git_root_job()

local function on_tree_change_handler(op, path, _) -- _ = upstream
    if M._config.update_on_change then
        if op == Enum.Operations.Switch then
            local changed = M.update_current_buffer()
            if not changed then
                vim.cmd(string.format("e %s", M.get_worktree_path(path)))
            end
        end
    end
end

local function emit_on_change(op, path, upstream)
    -- TODO: We don't have a way to async update what is running
    status:next_status(string.format("Running post %s callbacks", op))
    on_tree_change_handler(op, path, upstream)
    for idx = 1, #on_change_callbacks do
        on_change_callbacks[idx](op, path, upstream)
    end
end

local function change_dirs(path)
    local worktree_path = M.get_worktree_path(path)

    -- vim.loop.chdir(worktree_path)
    if Path:new(worktree_path):exists() then
        local cmd = string.format("cd %s", worktree_path)
        vim.cmd(cmd)
    else
        error('Could not chang to directory: ' ..worktree_path)
    end

    if M._config.clearjumps_on_change then
        vim.cmd("clearjumps")
    end
end

local function create_worktree_job(path, branch, found_branch)

    local worktree_add_cmd = 'git'
    local worktree_add_args = {'worktree', 'add'}

    if not found_branch then
        table.insert(worktree_add_args, '-b')
        table.insert(worktree_add_args, branch)
        table.insert(worktree_add_args, path)
    else
        table.insert(worktree_add_args, path)
        table.insert(worktree_add_args, branch)
    end

    return Job:new({
        command = worktree_add_cmd,
        args = worktree_add_args,
        cwd = git_worktree_root,
        on_start = function()
            status:next_status(worktree_add_cmd .. " " .. table.concat(worktree_add_args, " "))
        end
    })
end

-- A lot of this could be cleaned up if there was better job -> job -> function
-- communication.  That should be doable here in the near future
local function has_worktree(path, cb)
    local found = false
    local plenary_path = Path:new(path)

    local job = Job:new({
        'git', 'worktree', 'list', on_stdout = function(_, data)
            local start
            if plenary_path:is_absolute() then
                start = string.find(data, path, 1, true)
            else
                local worktree_path = Path:new(
                    string.format("%s" .. Path.path.sep .. "%s", git_worktree_root, path)
                )
                worktree_path = worktree_path:absolute()
                start = string.find(data, worktree_path, 1, true)
            end

            -- TODO: This is clearly a hack (do not think we need this anymore?)
            local start_with_head = string.find(data, string.format("[heads/%s]", path), 1, true)
            found = found or start or start_with_head
        end,
        cwd = git_worktree_root
    })

    job:after(function()
        cb(found)
    end)

    -- TODO: I really don't want status's spread everywhere... seems bad
    status:next_status("Checking for worktree " .. path)
    job:start()
end

local function failure(from, cmd, path, soft_error)
    return function(e)
        local error_message = string.format(
            "%s Failed: PATH %s CMD %s RES %s, ERR %s",
            from,
            path,
            vim.inspect(cmd),
            vim.inspect(e:result()),
            vim.inspect(e:stderr_result()))

        if soft_error then
            status:status(error_message)
        else
            error(error_message)
        end
    end
end

local function has_origin()
    local found = false
    local job = Job:new({
        'git', 'remote', 'show',
        on_stdout = function(_, data)
            data = vim.trim(data)
            found = found or data == 'origin'
        end,
        cwd = git_worktree_root,
    })

    -- TODO: I really don't want status's spread everywhere... seems bad
    job:after(function()
        status:status("found origin: " .. tostring(found))
    end):sync()

    return found
end

local function has_branch(branch, cb)
    local found = false
    local job = Job:new({
        'git', 'branch', on_stdout = function(_, data)
            -- remove  markere on current branch
            data = data:gsub("*","")
            data = vim.trim(data)
            found = found or data == branch
        end,
        cwd = git_worktree_root,
    })

    -- TODO: I really don't want status's spread everywhere... seems bad
    status:next_status(string.format("Checking for branch %s", branch))
    job:after(function()
        status:status("found branch: " .. tostring(found))
        cb(found)
    end):start()
end

local function create_worktree(path, branch, upstream, found_branch)
    local create = create_worktree_job(path, branch, found_branch)

    local worktree_path
    if Path:new(path):is_absolute() then
        worktree_path = path
    else
        worktree_path = Path:new(git_worktree_root, path):absolute()
    end

    local fetch = Job:new({
        'git', 'fetch', '--all',
        cwd = worktree_path,
        on_start = function()
            status:next_status("git fetch --all (This may take a moment)")
        end
    })

    local set_branch_cmd = 'git'
    local set_branch_args= {'branch', string.format('--set-upstream-to=%s/%s', upstream, branch)}
    local set_branch = Job:new({
        command = set_branch_cmd,
        args = set_branch_args,
        cwd = worktree_path,
        on_start = function()
            status:next_status(set_branch_cmd .. " " .. table.concat(set_branch_args, " "))
        end
    })

    -- TODO: How to configure origin???  Should upstream ever be the push
    -- destination?
    local set_push_cmd = 'git'
    local set_push_args = {'push', "--set-upstream", upstream,  branch, path}
    local set_push  = Job:new({
        command = set_push_cmd,
        args = set_push_args,
        cwd = worktree_path,
        on_start = function()
            status:next_status(set_push_cmd .. " " .. table.concat(set_push_args, " "))
        end
    })

    local rebase = Job:new({
        'git', 'rebase',
        cwd = worktree_path,
        on_start = function()
            status:next_status("git rebase")
        end
    })

    if upstream ~= nil then
        create:and_then_on_success(fetch)
        fetch:and_then_on_success(set_branch)

        if M._config.autopush then
            -- These are "optional" operations.
            -- We have to figure out how we want to handle these...
            set_branch:and_then(set_push)
            set_push:and_then(rebase)
            set_push:after_failure(failure("create_worktree", set_branch.args, worktree_path, true))
        else
            set_branch:and_then(rebase)
        end

        create:after_failure(failure("create_worktree", create.args, git_worktree_root))
        fetch:after_failure(failure("create_worktree", fetch.args, worktree_path))

        set_branch:after_failure(failure("create_worktree", set_branch.args, worktree_path, true))

        rebase:after(function()

            if rebase.code ~= 0 then
                status:status("Rebase failed, but that's ok.")
            end

            vim.schedule(function()
                emit_on_change(Enum.Operations.Create, path, upstream)
                M.switch_worktree(path)
            end)
        end)
    else
        create:after(function()
            vim.schedule(function()
                emit_on_change(Enum.Operations.Create, path, upstream)
                M.switch_worktree(path)
            end)
        end)
    end

    create:start()
end

M.create_worktree = function(path, branch, upstream)
    status:reset(8)

    if upstream == nil then
        if has_origin() then
            upstream = "origin"
        end
    end

    has_worktree(path, function(found)
        if found then
            error("worktree already exists")
        end

        has_branch(branch, function(found_branch)
            create_worktree(path, branch, upstream, found_branch)
        end)
    end)

end

M.switch_worktree = function(path)
    status:reset(2)
    has_worktree(path, function(found)

        if not found then
            error("worktree does not exists, please create it first " .. path)
        end

        vim.schedule(function()
            change_dirs(path)
            emit_on_change(Enum.Operations.Switch, path)
        end)

    end)
end

M.delete_worktree = function(path, force)
    status:reset(2)
    has_worktree(path, function(found)
        if not found then
            error(string.format("Worktree %s does not exist", path))
        end

        local cmd = {
            "git", "worktree", "remove", path
        }

        if force then
            table.insert(cmd, "--force")
        end

        local delete = Job:new(cmd)
        delete:after_success(vim.schedule_wrap(function()
            emit_on_change(Enum.Operations.Delete, path)
        end))

        delete:after_failure(failure(cmd, vim.loop.cwd()))
        delete:start()
    end)
end

M.set_worktree_root = function(wd)
    git_worktree_root = wd
end

M.set_current_worktree_path = function(wd)
    current_worktree_path = wd
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

    if not start then
        return false
    end

    local_name = local_name:sub(fin + 1)
    local final_path = Path:new({cwd, local_name}):absolute()

    if not Path:new(final_path):exists() then
        return false
    end

    local bufnr = vim.fn.bufnr(final_path, true)
    vim.api.nvim_set_current_buf(bufnr)
    return true
end

M.on_tree_change = function(cb)
    table.insert(on_change_callbacks, cb)
end

M.reset = function()
    on_change_callbacks = {}
end

M.get_root = function()
    return git_worktree_root
end

M.get_current_worktree_path = function()
    return current_worktree_path
end

M.get_worktree_path = function(path)
    if Path:new(path):is_absolute() then
        return path
    else
        return Path:new(git_worktree_root, path):absolute()
    end
end

M.setup = function(config)
    config = config or {}
    M._config = vim.tbl_deep_extend("force", {
        update_on_change = true,
        clearjumps_on_change = true,
        -- should this default to true or false?
        autopush = false,
    }, config)
end

M.set_status = function(msg)
    -- TODO: make this so #1
end

M.setup()
M.Operations = Enum.Operations

return M
