local Job = require("plenary.job")

local M = {}

-- A lot of this could be cleaned up if there was better job -> job -> function
-- communication.  That should be doable here in the near future
local function create_has_worktree(path, cb)
    local found = false
    local job = Job:new({
        'git', 'worktree', 'list', on_stdout = function(_, data)
            local start = string.find(data, string.format("[%s]", path), 1, true)
            found = found or start
        end
    })

    job:after(function()
        cb(found)
    end)
    job:start()
end

M.create_worktree = function(path, upstream)
    has_worktree(path)
end

M.selectWorktree = function(path)
end

return M


