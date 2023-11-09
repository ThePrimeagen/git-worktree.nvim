local Job = require("plenary").job
--local Path = require("plenary.path")
local Status = require("git-worktree.status")

local status = Status:new()

---@class GitWorktreeGitOps
local M = {}

--- @return boolean
function M.is_bare_repo()
    local inside_worktree_job = Job:new({
        "git",
        "rev-parse",
        "--is-bare-repository",
        cwd = vim.loop.cwd(),
    })

    local stdout, code = inside_worktree_job:sync()
    if code ~= 0 then
        status:log().error("Error in determining if we are in a worktree")
        return false
    end

    stdout = table.concat(stdout, "")

    if stdout == "true" then
        return true
    else
        return false
    end
end

--- @return boolean
function M.is_worktree()
    local inside_worktree_job = Job:new({
        "git",
        "rev-parse",
        "--is-inside-work-tree",
        cwd = vim.loop.cwd(),
    })

    local stdout, code = inside_worktree_job:sync()
    if code ~= 0 then
        status:log().error("Error in determining if we are in a worktree")
        return false
    end

    stdout = table.concat(stdout, "")

    if stdout == "true" then
        return true
    else
        return false
    end
end

-- @param is_worktree boolean
--- @return string|nil
function M.find_git_dir()
    local job = Job:new({
        "git",
        "rev-parse",
        "--show-toplevel",
        cwd = vim.loop.cwd(),
        on_stderr = function(_, data)
            status:log().info("ERROR: " .. data)
        end,
    })

    local stdout, code = job:sync()
    if code ~= 0 then
        status:log().error(
            "Error in determining the git root dir: code:"
                .. tostring(code)
                .. " out: "
                .. table.concat(stdout, "")
                .. "."
        )
        return nil
    end

    stdout = table.concat(stdout, "")
    status:log().info("cwd: " .. vim.loop.cwd())
    status:log().info("git root dir: " .. stdout)

    -- if is_worktree then
    --     -- if in worktree git dir returns absolute path
    --
    --     -- try to find the dot git folder (non-bare repo)
    --     local git_dir = Path:new(stdout)
    --     local has_dot_git = false
    --     for _, dir in ipairs(git_dir:_split()) do
    --         if dir == ".git" then
    --             has_dot_git = true
    --             break
    --         end
    --     end
    --
    --     if has_dot_git then
    --         if stdout == ".git" then
    --             return vim.loop.cwd()
    --         else
    --             local start = stdout:find("%.git")
    --             return stdout:sub(1, start - 2)
    --         end
    --     else
    --         local start = stdout:find("/worktrees/")
    --         return stdout:sub(0, start - 1)
    --     end
    -- elseif stdout == "." then
    --     -- we are in the root git dir
    --     return vim.loop.cwd()
    -- else
    -- if not in worktree git dir should be absolute
    return stdout
    -- end
end

--- @return string|nil
function M.find_git_toplevel()
    local find_toplevel_job = Job:new({
        "git",
        "rev-parse",
        "--show-toplevel",
        cwd = vim.loop.cwd(),
    })
    local stdout, code = find_toplevel_job:sync()
    if code == 0 then
        stdout = table.concat(stdout, "")
        return stdout
    else
        return nil
    end
end

function M.has_branch(branch, cb)
    local found = false
    local job = Job:new({
        "git",
        "branch",
        on_stdout = function(_, data)
            -- remove  markere on current branch
            data = data:gsub("*", "")
            data = vim.trim(data)
            found = found or data == branch
        end,
        cwd = vim.loop.cwd(),
    })

    -- TODO: I really don't want status's spread everywhere... seems bad
    status:next_status(string.format("Checking for branch %s", branch))
    job:after(function()
        status:status("found branch: " .. tostring(found))
        cb(found)
    end):start()
end

function M.has_origin()
    local found = false
    local job = Job:new({
        "git",
        "remote",
        "show",
        on_stdout = function(_, data)
            data = vim.trim(data)
            found = found or data == "origin"
        end,
        cwd = vim.loop.cwd(),
    })

    -- TODO: I really don't want status's spread everywhere... seems bad
    job:after(function()
        status:status("found origin: " .. tostring(found))
    end):sync()

    return found
end

return M
