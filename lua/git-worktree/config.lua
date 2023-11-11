local M = {}

---@class GitWorktree.Config
local defaults = {
    change_directory_command = 'cd',
    update_on_change = true,
    update_on_change_command = 'e .',
    clearjumps_on_change = true,
    confirm_telescope_deletions = true,
    autopush = false,
}

---@type GitWorktree.Config
M.options = {}

---@param opts? GitWorktree.Config
function M.setup(opts)
    M.options = vim.tbl_deep_extend('force', defaults, opts or {})
end

M.setup()

return M
