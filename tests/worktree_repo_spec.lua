local git_worktree = require('git-worktree')
local Path = require('plenary.path')

local harness = require('tests.git_harness')
local in_repo_from_origin_no_worktrees = harness.in_repo_from_origin_no_worktrees
local in_repo_from_origin_1_worktree = harness.in_repo_from_origin_1_worktree
local check_branch_upstream = harness.check_branch_upstream



describe('git-worktree non bare repo', function()

    local completed_create = false
    local completed_switch = false
    local completed_delete = false

    local reset_variables = function()
        completed_create = false
        completed_switch = false
        completed_delete = false
    end

    before_each(function()
        reset_variables()
        git_worktree.on_tree_change(function(op, _, _)
            if op == git_worktree.Operations.Create then
                completed_create = true
            end
            if op == git_worktree.Operations.Switch then
                completed_switch = true
            end
            if op == git_worktree.Operations.Delete then
                completed_delete = true
            end
        end)
    end)

    after_each(function()
        git_worktree.reset()
    end)

    it('can create a worktree from a bare and switch to it', in_repo_from_origin_no_worktrees(function()

        local random_str = git_worktree.get_root():sub(git_worktree.get_root():len()-4)
        local branch = "featB"
        local upstream = "origin"
        local path = "../git_worktree_test_repo_" .. branch .. "_" .. random_str
        git_worktree.create_worktree(path, branch, upstream)

        vim.fn.wait(
            10000,
            function()
                return completed_create and completed_switch
            end,
            1000
        )

        -- Check to make sure directory was switched
        local expected_path = Path:new(git_worktree:get_root() .. '/' .. path):normalize()
        assert.are.same(expected_path, vim.loop.cwd())

        -- check to make sure branch/upstream is correct
        local correct_branch, correct_upstream = check_branch_upstream(branch, upstream)
        assert.True(correct_branch)
        assert.True(correct_upstream)

    end))

    it('from a repo with one worktree, able to switch to worktree', in_repo_from_origin_1_worktree(function()

        local random_str = git_worktree.get_root():sub(git_worktree.get_root():len()-4)
        local path = "../git_worktree_test_repo_featB_"..random_str
        git_worktree.switch_worktree(path)

        vim.fn.wait(
            10000,
            function()
                return completed_switch
            end,
            1000
        )

        git_worktree:reset()

        local expected_path = Path:new(git_worktree:get_root() .. '/'..path):normalize()

        -- Check to make sure directory was switched
        assert.are.same(vim.loop.cwd(), expected_path)

    end))

    it('from a repo with one worktree, able to delete the worktree', in_repo_from_origin_1_worktree(function()

        local random_str = git_worktree.get_root():sub(git_worktree.get_root():len()-4)
        local path = "../git_worktree_test_repo_featB_"..random_str
        git_worktree.delete_worktree(path, true)

        vim.fn.wait(
            10000,
            function()
                return completed_delete
            end,
            1000
        )

        -- Check to make sure directory was not switched
        assert.are.same(vim.loop.cwd(), git_worktree:get_root())

    end))
end)
