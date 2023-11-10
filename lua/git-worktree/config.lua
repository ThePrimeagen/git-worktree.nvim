local M = {}

---@class GitWorktreeConfig

---@class GitWorktreePartialConfig
---@field change_directory_command?  string
---@field update_on_change? boolean
---@field update_on_change_command? string
---@field clearjumps_on_change? boolean
---@field confirm_telescope_deletions? boolean
---@field autopush? boolean

---@return GitWorktreeConfig
function M.get_default_config()
    return {
        change_directory_command = 'cd',
        update_on_change = true,
        update_on_change_command = 'e .',
        clearjumps_on_change = true,
        confirm_telescope_deletions = true,
        autopush = false,
    }
end

---@param partial_config GitWorktreePartialConfig
---@param latest_config GitWorktreeConfig?
---@return GitWorktreeConfig
function M.merge_config(partial_config, latest_config)
    local config = latest_config or M.get_default_config()

    config = vim.tbl_extend('force', config, partial_config)

    return config
end

return M
