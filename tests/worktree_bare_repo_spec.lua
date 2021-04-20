local git_worktree = require('git-worktree')
local Path = require('plenary.path')

local harness = require('tests.git_harness')
local in_bare_repo_from_origin_no_worktrees = harness.in_bare_repo_from_origin_no_worktrees
local in_bare_repo_from_origin_1_worktree = harness.in_bare_repo_from_origin_1_worktree

local completed_create = false
local completed_switch = false
local completed_delete = false

local reset_variables = function()
    completed_create = false
    completed_switch = false
    completed_delete = false
end

describe('git-worktree bare repo', function()

    it('can create a worktree from a bare repo and switch to it', in_bare_repo_from_origin_no_worktrees(function()

        reset_variables()
        git_worktree.on_tree_change(function(op, _, _)
            if op == git_worktree.Operations.Create then
                completed_create = true
            end
            if op == git_worktree.Operations.Switch then
                completed_switch = true
            end
        end)

        git_worktree.create_worktree("master", "origin/master")

        vim.fn.wait(
            10000,
            function()
                return completed_create and completed_switch
            end,
            100
        )

        git_worktree:reset()

        assert.are.same(vim.loop.cwd(), git_worktree:get_root() .. '/master')
    end))

    it('from a bare repo with one worktree, able to switch to worktree', in_bare_repo_from_origin_1_worktree(function()

        reset_variables()
        git_worktree.on_tree_change(function(op, _, _)
            if op == git_worktree.Operations.Switch then
                completed_switch = true
            end
        end)

        git_worktree.switch_worktree("master")

        vim.fn.wait(
            10000,
            function()
                return completed_switch
            end,
            100
        )

        git_worktree:reset()

        assert.are.same(vim.loop.cwd(), git_worktree:get_root() .. '/master')
    end))

    it('from a bare repo with one worktree, able to delete the worktree', in_bare_repo_from_origin_1_worktree(function()

        reset_variables()
        git_worktree.on_tree_change(function(op, _, _)
            if op == git_worktree.Operations.Delete then
                completed_delete = true
            end
        end)

        git_worktree.delete_worktree("master")

        vim.fn.wait(
            10000,
            function()
                return completed_delete
            end,
            100
        )

        git_worktree:reset()

        assert.are.same(vim.loop.cwd(), git_worktree:get_root())
    end))
end)
