local M = {}

---Runs a system command and errors if it fails
---@param cmd string | table Command to be ran
---@param ignore_err boolean? Whether the error should be ignored
---@param error_msg string? The error message to be emitted on command failure
---@return string The output of the system command
function M.run(cmd, ignore_err, error_msg)
    if ignore_err == nil then
        ignore_err = false
    end

    local output = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 and not ignore_err then
        error(error_msg or ('Command failed: ↓\n' .. cmd .. '\nOutput from command: ↓\n' .. output))
    end
    return output
end

local function is_macos()
    return vim.loop.os_uname().sysname == 'Darwin'
end

---Create a temporary directory for use
---@param suffix string? The suffix to be appended to the temp directory, ideally avoid spaces in your suffix
---@return string The path to the temporary directory
function M.create_temp_dir(suffix)
    suffix = 'git-worktree-' .. (suffix or '')

    local cmd
    if is_macos() then
        cmd = string.format('mktemp -d -t %s', suffix)
    else
        cmd = string.format('mktemp -d --suffix=%s', suffix)
    end

    local prefix = is_macos() and '/private' or ''
    return prefix .. vim.trim(M.run(cmd))
end

return M
