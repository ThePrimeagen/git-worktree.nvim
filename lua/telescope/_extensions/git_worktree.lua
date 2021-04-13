local Job = require("plenary.job")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local action_set = require "telescope.actions.set"
local action_state = require "telescope.actions.state"
local conf = require("telescope.config").values
local gwt = require("git-worktree")

local list_worktrees = function(cb)
	local job = Job:new({
		"git",
		"worktree",
		"list",
		on_exit = vim.schedule_wrap(function(j_self, _, _)
			local output = j_self:result()
			cb(output)
		end),
	})

	job:start()
end

local telescope_git_worktree = function()
	local cb = function(output, _)
		if output then
			pickers.new({}, {
				prompt_prefix = "Git Worktrees >",
				finder = finders.new_table({
					results = output,
				}),
				sorter = conf.generic_sorter({}),
				attach_mappings = function()
                    action_set.select:replace(function(prompt_bufnr, type)
                        local selection = action_state.get_selected_entry(prompt_bufnr)
                        local worktree = nil
                        for section in selection[1]:gmatch("%[(.*)%]") do
                            worktree = section
                        end
                        if worktree ~= nil then
                            gwt.switch_worktree(worktree)
                        end
                    end)
                    --TODO add delete worktree
                    --TODO add create worktree? is this possible?
					return true
				end,
			}):find()
		end
	end
	list_worktrees(cb)
end

return require("telescope").register_extension({
	exports = {
		git_worktrees = telescope_git_worktree,
	},
})
