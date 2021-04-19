local Path = require("plenary.path")
local Window = require("plenary.window.float")
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
    return worktree_line[1]
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

local create_worktree = function()
    require("telescope.builtin").git_branches(
        {
            attach_mappings = function(_)

                actions.select_default:replace(
                    function(prompt_bufnr, _)
                        local selected_entry = action_state.get_selected_entry()
                        actions.close(prompt_bufnr)
                        if selected_entry ~= nil then
                            local branch = selected_entry.value

                            local window = Window.percentage_range_window(0.5, 0.2)
                            vim.api.nvim_buf_set_option(window.bufnr, "buftype",
                                                        "prompt")
                            vim.fn.prompt_setprompt(window.bufnr, "Worktree Location: ")
                            vim.fn.prompt_setcallback(window.bufnr, function(text)
                                vim.api.nvim_win_close(window.win_id, true)
                                vim.api.nvim_buf_delete(window.bufnr, {force = true})
                                if text ~= "" then
                                    gwt.create_worktree(text, branch)
                                else
                                    print("No path to create worktree")
                                end
                            end)
                            vim.cmd [[startinsert]]

                        end
                    end)

                -- do we need to replace other default maps?

                return true
            end
        })
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

            return true
        end
    }):find()
end

return require("telescope").register_extension(
           {
        exports = {
            git_worktrees = telescope_git_worktree,
            create_git_worktree = create_worktree
        }
    })
