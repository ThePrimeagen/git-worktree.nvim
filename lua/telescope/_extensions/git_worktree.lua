local Job = require("plenary.job")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

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
					--TODO
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
