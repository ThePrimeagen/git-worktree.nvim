---@class GitWorktreeLog
---@field logger any the plenary logging object
local M = {}

---@return string
local function set_log_level()
    local log_levels = { 'trace', 'debug', 'info', 'warn', 'error', 'fatal' }
    local log_level = vim.env.GIT_WORKTREE_NVIM_LOG or vim.g.git_worktree_log_level

    for _, level in pairs(log_levels) do
        if level == log_level then
            return log_level
        end
    end

    return 'warn' -- default, if user hasn't set to one from log_levels
end

---@return GitWorktreeLog
function M:new(options)
    local obj = vim.tbl_extend('force', {
        -- What to do here?
        logger = require('plenary.log').new {
            plugin = 'git-worktree-nvim',
            level = set_log_level(),
        },
    }, options or {})

    setmetatable(obj, self)
    self.__index = self

    return obj
end

---Resets the count and index on the status logger
---
---@param count integer
function M:reset(count)
    self.count = count
    self.idx = 0
end

---@param msg string
function M:_get_string(msg)
    return string.format('%d / %d: %s', self.idx, self.count, msg)
end

---@param msg string
function M:next_status(msg)
    self.idx = self.idx + 1
    local fmt_msg = self:_get_string(msg)
    print(fmt_msg)
    self.logger.info(fmt_msg)
end

---@param msg string
function M:next_error(msg)
    self.idx = self.idx + 1
    local fmt_msg = self:_get_string(msg)
    error(fmt_msg)
    self.logger.error(fmt_msg)
end

---@param msg string
function M:status(msg)
    local fmt_msg = self:_get_string(msg)
    print(fmt_msg)
    self.logger.info(fmt_msg)
end

---@param msg string
function M:error(msg)
    local fmt_msg = self:_get_string(msg)
    error(fmt_msg)
    self.logger.error(fmt_msg)
end

---@return GitWorktreeLog
function M:log()
    return self.logger
end

return M
