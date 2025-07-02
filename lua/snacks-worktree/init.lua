local git_worktree = require("git-worktree")
local Snacks = require("snacks")
local uv = vim.uv or vim.loop
local force_next_deletion = false

local snacks_worktree = {}

local confirm_deletion = function(item, proceed)
    local prompt = "Delete worktree %q?"
    if force_next_deletion then
        prompt = "Force deletion of worktree %q?"
    end
    Snacks.picker.select({ "Yes", "No" }, { prompt = (prompt):format(item.path) }, function(_, idx)
        if idx ~= 1 then
            print("Didn't delete worktree")
            return
        end
        proceed()
    end)
end

local delete_success_handler = function()
    force_next_deletion = false
end

local delete_failure_handler = function()
    print("Deletion failed, use <C-f> to force the next deletion")
end

local toggle_forced_deletion = function()
    -- redraw otherwise the message is not displayed when in insert mode
    if force_next_deletion then
        print("The next deletion will not be forced")
        vim.fn.execute("redraw")
    else
        print("The next deletion will be forced")
        vim.fn.execute("redraw")
        force_next_deletion = true
    end
end

local switch_worktree = function(picker, item)
    local worktree_path = item.path
    picker:close()
    if worktree_path ~= nil then
        git_worktree.switch_worktree(worktree_path)
    end
end
local create_input_prompt = function(cb)
    vim.ui.input({
        prompt = "Worktree Location: ",
    }, function(value)
        cb(value)
    end)
end

function snacks_worktree.create_worktree()
    Snacks.picker({
        all = false,
        finder = "git_branches",
        format = "git_branch",
        preview = "git_log",
        confirm = function(picker, item)
            local branch = item.branch
            picker:close()
            create_input_prompt(function(name)
                if name == "" then
                    name = branch
                end
                git_worktree.create_worktree(name, branch)
            end)
        end,
    })
end

local delete_worktree = function(picker, item)
    if not item then
        vim.notify(vim.inspect(item))
        Snacks.notify.warn("No worktree to delete", { title = "Snacks Picker" })
    end
    confirm_deletion(item, function()
        local worktree_path = item.path
        picker:close()
        if worktree_path ~= nil then
            git_worktree.delete_worktree(worktree_path, force_next_deletion, {
                on_failure = delete_failure_handler,
                on_success = delete_success_handler,
            })
        end
    end)
end

local finder = function(opts, ctx)
    local args = { "worktree", "list" }
    local cwd = svim.fs.normalize(opts and opts.cwd or uv.cwd() or ".") or nil
    cwd = Snacks.git.get_root(cwd)
    git_worktree.setup_git_info()
    local current = git_worktree.get_current_worktree_path()
    return require("snacks.picker.source.proc").proc({
        opts,
        {
            cwd = cwd,
            cmd = "git",
            args = args,
            ---@param item snacks.picker.finder.Item
            transform = function(item)
                item.cwd = cwd
                local fields = vim.split(string.gsub(item.text, "%s+", " "), " ")
                item.path = fields[1]
                item.current = current == item.path
                item.sha = fields[2]
                item.branch = fields[3]
                if item.sha == "(bare)" then
                    return false
                end
            end,
        },
    }, ctx)
end

local format = function(item, picker)
    local a = Snacks.picker.util.align
    local ret = {} ---@type snacks.picker.Highlight[]
    if item.current then
        ret[#ret + 1] = { a("", 2), "SnacksPickerGitBranchCurrent" }
    else
        ret[#ret + 1] = { a("", 2) }
    end
    ret[#ret + 1] = { a(item.branch, 30, { truncate = true }), "SnacksPickerGitBranch" }
    ret[#ret + 1] = { a(item.sha, 8, { truncate = true }), "SnacksPickerGitCommit" }
    ret[#ret + 1] = { " " }
    ret[#ret + 1] = { a(item.path, 100, { truncate = true }), "SnacksPickerDirectory" }
    return ret
end

function snacks_worktree.pick_git_worktree()
    if not Snacks then
        return
    end
    local config = {
        all = false,
        preview = "none",
        finder = finder,
        format = format,
        layout = {
            preview = false,
        },
        confirm = switch_worktree,
        actions = {
            delete_worktree = delete_worktree,
            toggle_forced_deletion = toggle_forced_deletion,
        },
        win = {
            input = {
                keys = {
                    ["<c-d>"] = { "delete_worktree", mode = { "n", "i" } },
                    ["<c-f>"] = { "toggle_forced_deletion", mode = { "n", "i" } },
                },
            },
        },
        ---@param picker snacks.Picker
        on_show = function(picker)
            for i, item in ipairs(picker:items()) do
                if item.current then
                    picker.list:view(i)
                    Snacks.picker.actions.list_scroll_center(picker)
                    break
                end
            end
        end,
    }

    Snacks.picker.pick(config)
end

return snacks_worktree
