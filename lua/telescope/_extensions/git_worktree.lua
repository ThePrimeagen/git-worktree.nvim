local strings = require("plenary.strings")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local utils = require("telescope.utils")
local action_set = require("telescope.actions.set")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local git_worktree = require("git-worktree")

local force_next_deletion = false

-- Get the path of the selected worktree
-- @param prompt_bufnr number: the prompt buffer number
-- @return string: the path of the selected worktree
local get_worktree_path = function(prompt_bufnr)
    local selection = action_state.get_selected_entry(prompt_bufnr)
    return selection.path
end

-- Switch to the selected worktree
-- @param prompt_bufnr number: the prompt buffer number
-- @return nil
local switch_worktree = function(prompt_bufnr)
    local worktree_path = get_worktree_path(prompt_bufnr)
    actions.close(prompt_bufnr)
    if worktree_path ~= nil then
        git_worktree.switch_worktree(worktree_path)
    end
end

-- Toggle the forced deletion of the next worktree
-- @return nil
local toggle_forced_deletion = function()
    -- redraw otherwise the message is not displayed when in insert mode
    if force_next_deletion then
        vim.print("The next deletion will not be forced")
        vim.fn.execute("redraw")
    else
        vim.print("The next deletion will be forced")
        vim.fn.execute("redraw")
        force_next_deletion = true
    end
end

-- Handler for successful deletion
-- @return nil
local delete_success_handler = function()
    force_next_deletion = false
end

-- Handler for failed deletion
-- @return nil
local delete_failure_handler = function()
    print("Deletion failed, use <C-f> to force the next deletion")
end

-- Ask the user to confirm the deletion of a worktree
-- @param forcing boolean: whether the deletion is forced
-- @return boolean: whether the deletion is confirmed
local ask_to_confirm_deletion = function(forcing)
    if forcing then
        return vim.fn.input("Force deletion of worktree? [y/n]: ")
    end

    return vim.fn.input("Delete worktree? [y/n]: ")
end

-- Confirm the deletion of a worktree
-- @param forcing boolean: whether the deletion is forced
-- @return boolean: whether the deletion is confirmed
local confirm_deletion = function(forcing)
    if not git_worktree._config.confirm_telescope_deletions then
        return true
    end

    local confirmed = ask_to_confirm_deletion(forcing)

    if string.sub(string.lower(confirmed), 0, 1) == "y" then
        return true
    end

    print("Didn't delete worktree")
    return false
end

-- Delete the selected worktree
-- @param prompt_bufnr number: the prompt buffer number
-- @return nil
local delete_worktree = function(prompt_bufnr)
    if not confirm_deletion() then
        return
    end

    local worktree_path = get_worktree_path(prompt_bufnr)
    actions.close(prompt_bufnr)
    if worktree_path ~= nil then
        git_worktree.delete_worktree(worktree_path, force_next_deletion, {
            on_failure = delete_failure_handler,
            on_success = delete_success_handler,
        })
    end
end

-- Create a prompt to get the path of the new worktree
-- @param cb function: the callback to call with the path
-- @return nil
local create_input_prompt = function(cb)
    local subtree = vim.fn.input("Path to subtree > ")
    cb(subtree)
end

-- Create a worktree
-- @param opts table: the options for the telescope picker (optional)
-- @return nil
local create_worktree = function(opts)
    opts = opts or {}
    opts.attach_mappings = function()
        actions.select_default:replace(function(prompt_bufnr, _)
            local selected_entry = action_state.get_selected_entry()
            local current_line = action_state.get_current_line()

            actions.close(prompt_bufnr)

            local branch = selected_entry ~= nil and selected_entry.value or current_line

            if branch == nil then
                return
            end

            create_input_prompt(function(name)
                if name == "" then
                    name = branch
                end
                git_worktree.create_worktree(name, branch)
            end)
        end)

        return true
    end
    require("telescope.builtin").git_branches(opts)
end

-- List the git worktrees
-- @param opts table: the options for the telescope picker (optional)
-- @return nil
local telescope_git_worktree = function(opts)
    opts = opts or {}
    local output = utils.get_os_command_output({ "git", "worktree", "list" })
    local results = {}
    local widths = {
        path = 0,
        sha = 0,
        branch = 0,
    }

    local parse_line = function(line)
        local fields = vim.split(string.gsub(line, "%s+", " "), " ")
        local entry = {
            path = fields[1],
            sha = fields[2],
            branch = fields[3],
        }

        if entry.sha ~= "(bare)" then
            local index = #results + 1
            for key, val in pairs(widths) do
                if key == "path" then
                    local path_len = strings.strdisplaywidth(entry[key] or "")
                    widths[key] = math.max(val, path_len)
                else
                    widths[key] = math.max(val, strings.strdisplaywidth(entry[key] or ""))
                end
            end

            table.insert(results, index, entry)
        end
    end

    for _, line in ipairs(output) do
        parse_line(line)
    end

    if #results == 0 then
        return
    end

    local displayer = require("telescope.pickers.entry_display").create({
        separator = " ",
        items = {
            { width = widths.branch },
            { width = widths.path },
            { width = widths.sha },
        },
    })

    local make_display = function(entry)
        return displayer({
            { entry.branch, "TelescopeResultsIdentifier" },
            { utils.transform_path(opts, entry.path) },
            { entry.sha },
        })
    end

    pickers
        .new(opts or {}, {
            prompt_title = "Git Worktrees",
            finder = finders.new_table({
                results = results,
                entry_maker = function(entry)
                    entry.value = entry.branch
                    entry.ordinal = entry.branch
                    entry.display = make_display
                    return entry
                end,
            }),
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(_, map)
                action_set.select:replace(switch_worktree)

                map("i", "<c-d>", delete_worktree)
                map("n", "<c-d>", delete_worktree)
                map("i", "<c-f>", toggle_forced_deletion)
                map("n", "<c-f>", toggle_forced_deletion)

                return true
            end,
        })
        :find()
end

-- Register the extension
-- @return table: the extension
return require("telescope").register_extension({
    exports = {
        git_worktrees = telescope_git_worktree,
        create_git_worktree = create_worktree,
    },
})
