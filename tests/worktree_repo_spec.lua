local git_worktree = require('git-worktree')
local Path = require('plenary.path')

local harness = require('tests.git_harness')
local in_repo_from_origin_no_worktrees = harness.in_repo_from_origin_no_worktrees
local in_repo_from_origin_1_worktree = harness.in_repo_from_origin_1_worktree

local completed_create = false
local completed_switch = false
local completed_delete = false

local reset_variables = function()
    completed_create = false
    completed_switch = false
    completed_delete = false
end

describe('git-worktree non bare repo', function()

    it('can create a worktree from a bare and switch to it', in_repo_from_origin_no_worktrees(function()

        reset_variables()
        git_worktree.on_tree_change(function(op, _, _)
            if op == git_worktree.Operations.Create then
                completed_create = true
            end
            if op == git_worktree.Operations.Switch then
                completed_switch = true
            end
        end)

        git_worktree.create_worktree("../git_worktree_test_repo_featB", "origin/featB")

        vim.fn.wait(
            10000,
            function()
                return completed_create and completed_switch
            end,
            1000
        )

        git_worktree:reset()

        local expected_path = Path:new(git_worktree:get_root() .. '/../git_worktree_test_repo_featB'):normalize()
        assert.are.same(vim.loop.cwd(), expected_path)
    end))

    it('from a repo with one worktree, able to switch to worktree', in_repo_from_origin_1_worktree(function()

        reset_variables()
        git_worktree.on_tree_change(function(op, _, _)
            if op == git_worktree.Operations.Switch then
                completed_switch = true
            end
        end)

        local random_str = git_worktree.get_root():sub(git_worktree.get_root():len()-4)
        git_worktree.switch_worktree("../git_worktree_test_repo_featB"..random_str)

        vim.fn.wait(
            10000,
            function()
                return completed_switch
            end,
            1000
        )

        git_worktree:reset()

        local expected_path = Path:new(git_worktree:get_root() .. '/../git_worktree_test_repo_featB'..random_str):normalize()
        assert.are.same(vim.loop.cwd(), expected_path)
    end))

    it('from a repo with one worktree, able to delete the worktree', in_repo_from_origin_1_worktree(function()

        reset_variables()
        git_worktree.on_tree_change(function(op, _, _)
            if op == git_worktree.Operations.Delete then
                completed_delete = true
            end
        end)

        local random_str = git_worktree.get_root():sub(git_worktree.get_root():len()-4)
        git_worktree.delete_worktree("../git_worktree_test_repo_featB"..random_str,true)

        vim.fn.wait(
            10000,
            function()
                return completed_delete
            end,
            1000
        )

        git_worktree:reset()

        assert.are.same(vim.loop.cwd(), git_worktree:get_root())
    end))
end)
