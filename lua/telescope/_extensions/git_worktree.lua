local Path = require("plenary.path")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_set = require("telescope.actions.set")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local gwt = require("git-worktree")

local get_worktree_path = function(prompt_bufnr)
    local selection = action_state.get_selected_entry(prompt_bufnr)
    local worktree_line = {}
    for section in selection[1]:gmatch("%S+") do
        table.insert(worktree_line, section)
    end
    local rel_path = Path:new(worktree_line[1])
    return rel_path:make_relative(gwt.get_root())
end

local switch_worktree = function(prompt_bufnr)
    local worktree_path = get_worktree_path(prompt_bufnr)
    actions.close(prompt_bufnr)
    if worktree_path ~= nil then
        gwt.switch_worktree(worktree_path)
    end
end

local delete_worktree = function(prompt_bufnr, force)
    local worktree_path = get_worktree_path(prompt_bufnr)
    actions.close(prompt_bufnr)
    if worktree_path ~= nil then
        gwt.delete_worktree(worktree_path, force)
    end
end

local create_worktree = function(prompt_bufnr)
    local worktree_path = action_state.get_current_line()
    actions.close(prompt_bufnr)
end

local telescope_git_worktree = function(opts)
    opts = opts or {}
    pickers.new({}, {
        prompt_prefix = "Git Worktrees >",
        finder = finders.new_oneshot_job(vim.tbl_flatten({"git", "worktree", "list"}),
                                         opts),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(_, map)
            action_set.select:replace(switch_worktree)

            map("i", "<c-d>", function(prompt_bufnr)
                delete_worktree(prompt_bufnr)
            end)
            map("n", "<c-d>", function(prompt_bufnr)
                delete_worktree(prompt_bufnr)
            end)
            map("i", "<c-D>", function(prompt_bufnr)
                delete_worktree(prompt_bufnr, true)
            end)
            map("n", "<c-D>", function(prompt_bufnr)
                delete_worktree(prompt_bufnr, true)
            end)

            map("i", "<c-e>", create_worktree)
            map("n", "<c-e>", create_worktree)

            return true
        end
    }):find()
end

return require("telescope").register_extension(
           {exports = {git_worktrees = telescope_git_worktree}})
