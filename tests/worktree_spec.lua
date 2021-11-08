local git_worktree = require('git-worktree')
local Path = require('plenary.path')

local harness = require('tests.git_harness')
local in_non_git_repo = harness.in_non_git_repo
local in_bare_repo_from_origin_no_worktrees = harness.in_bare_repo_from_origin_no_worktrees
local in_repo_from_origin_no_worktrees = harness.in_repo_from_origin_no_worktrees
local in_bare_repo_from_origin_1_worktree = harness.in_bare_repo_from_origin_1_worktree
local in_repo_from_origin_1_worktree = harness.in_repo_from_origin_1_worktree
local in_repo_from_local_no_worktrees = harness.in_repo_from_local_no_worktrees
local in_bare_repo_from_origin_2_worktrees = harness.in_bare_repo_from_origin_2_worktrees
local in_repo_from_origin_2_worktrees = harness.in_repo_from_origin_2_worktrees
local in_bare_repo_from_origin_2_similar_named_worktrees = harness.in_bare_repo_from_origin_2_similar_named_worktrees
local in_repo_from_origin_2_similar_named_worktrees = harness.in_repo_from_origin_2_similar_named_worktrees
local check_git_worktree_exists = harness.check_git_worktree_exists
local check_branch_upstream = harness.check_branch_upstream

describe('git-worktree', function()

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

    describe('Create', function()

        it('can create a worktree(from origin)(relative path) from a bare repo and switch to it',
            in_bare_repo_from_origin_no_worktrees(function()

            local branch = "master"
            local upstream = "origin"
            local path = "master"
            git_worktree.create_worktree(path, branch, upstream)

            vim.fn.wait(
            10000,
            function()
                return completed_create and completed_switch
            end,
            1000
            )

            local expected_path = git_worktree:get_root() .. Path.path.sep .. path
            -- Check to make sure directory was switched
            assert.are.same(expected_path, vim.loop.cwd())

            -- Check to make sure it is added to git worktree list
            assert.True(check_git_worktree_exists(expected_path))

            -- check to make sure branch/upstream is correct
            local correct_branch, correct_upstream = check_branch_upstream(branch, upstream)
            assert.True(correct_branch)
            assert.True(correct_upstream)

        end))

        it('can create a worktree(from origin)(absolute path) from a bare repo and switch to it',
            in_bare_repo_from_origin_no_worktrees(function()

            local branch = "master"
            local upstream = "origin"
            local path = git_worktree.get_root() .. Path.path.sep .. "master"
            git_worktree.create_worktree(path, branch, upstream)

            vim.fn.wait(
            10000,
            function()
                return completed_create and completed_switch
            end,
            1000
            )

            -- Check to make sure directory was switched
            assert.are.same(vim.loop.cwd(), path)

            -- Check to make sure it is added to git worktree list
            assert.True(check_git_worktree_exists(path))

            -- check to make sure branch/upstream is correct
            local correct_branch, correct_upstream = check_branch_upstream(branch, upstream)
            assert.True(correct_branch)
            assert.True(correct_upstream)

        end))

        it('can create a worktree(from origin)(relative path) from a repo and switch to it',
            in_repo_from_origin_no_worktrees(function()

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

            -- Check to make sure it is added to git worktree list
            assert.True(check_git_worktree_exists(expected_path))

            -- check to make sure branch/upstream is correct
            local correct_branch, correct_upstream = check_branch_upstream(branch, upstream)
            assert.True(correct_branch)
            assert.True(correct_upstream)

        end))

        it('can create a worktree(from origin)(absolute path) from a repo and switch to it',
            in_repo_from_origin_no_worktrees(function()

            local random_str = git_worktree.get_root():sub(git_worktree.get_root():len()-4)
            local branch = "featB"
            local upstream = "origin"
            local path = "/tmp/git_worktree_test_repo_" .. branch .. "_" .. random_str

            git_worktree.create_worktree(path, branch, upstream)

            vim.fn.wait(
            10000,
            function()
                return completed_create and completed_switch
            end,
            1000
            )

            -- Check to make sure directory was switched
            assert.are.same(path, vim.loop.cwd())

            -- Check to make sure it is added to git worktree list
            assert.True(check_git_worktree_exists(path))

            -- check to make sure branch/upstream is correct
            local correct_branch, correct_upstream = check_branch_upstream(branch, upstream)
            assert.True(correct_branch)
            assert.True(correct_upstream)

        end))

        it('can create a worktree(no upstream but detect origin)(relative path) from a bare repo and switch to it',
            in_bare_repo_from_origin_no_worktrees(function()

            local branch = "master"
            local upstream = "origin"
            local path = "master"
            git_worktree.create_worktree(path, branch)

            vim.fn.wait(
            10000,
            function()
                return completed_create and completed_switch
            end,
            1000
            )

            local expected_path = git_worktree:get_root() .. '/' .. path

            -- Check to make sure directory was switched
            assert.are.same(expected_path, vim.loop.cwd())

            -- Check to make sure it is added to git worktree list
            assert.True(check_git_worktree_exists(expected_path))

            -- check to make sure branch/upstream is correct
            local correct_branch, correct_upstream = check_branch_upstream(branch, upstream)
            assert.True(correct_branch)
            assert.True(correct_upstream)

        end))

        it('can create a worktree(no upstream but detect origin)(absolute path) from a bare repo and switch to it',
            in_bare_repo_from_origin_no_worktrees(function()

            local branch = "master"
            local upstream = "origin"
            local path = git_worktree:get_root() .. Path.path.sep .. "master"

            git_worktree.create_worktree(path, branch)

            vim.fn.wait(
            10000,
            function()
                return completed_create and completed_switch
            end,
            1000
            )

            -- Check to make sure directory was switched
            assert.are.same(path, vim.loop.cwd())

            -- Check to make sure it is added to git worktree list
            assert.True(check_git_worktree_exists(path))

            -- check to make sure branch/upstream is correct
            local correct_branch, correct_upstream = check_branch_upstream(branch, upstream)
            assert.True(correct_branch)
            assert.True(correct_upstream)

        end))

        it('can create a worktree(no upstream but detect origin)(relative path) from a repo and switch to it',
            in_repo_from_origin_no_worktrees(function()

            local random_str = git_worktree.get_root():sub(git_worktree.get_root():len()-4)
            local branch = "featB"
            local upstream = "origin"
            local path = "../git_worktree_test_repo_" .. branch .. "_" .. random_str
            git_worktree.create_worktree(path, branch)

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

            -- Check to make sure it is added to git worktree list
            assert.True(check_git_worktree_exists(expected_path))

            -- check to make sure branch/upstream is correct
            local correct_branch, correct_upstream = check_branch_upstream(branch, upstream)
            assert.True(correct_branch)
            assert.True(correct_upstream)

        end))

        it('can create a worktree(no upstream but detect origin)(absolute path) from a repo and switch to it',
            in_repo_from_origin_no_worktrees(function()

            local random_str = git_worktree.get_root():sub(git_worktree.get_root():len()-4)
            local branch = "featB"
            local upstream = "origin"
            local path = "/tmp/git_worktree_test_repo_" .. branch .. "_" .. random_str

            git_worktree.create_worktree(path, branch)

            vim.fn.wait(
            10000,
            function()
                return completed_create and completed_switch
            end,
            1000
            )

            -- Check to make sure directory was switched
            assert.are.same(path, vim.loop.cwd())

            -- Check to make sure it is added to git worktree list
            assert.True(check_git_worktree_exists(path))

            -- check to make sure branch/upstream is correct
            local correct_branch, correct_upstream = check_branch_upstream(branch, upstream)
            assert.True(correct_branch)
            assert.True(correct_upstream)

        end))

        it('can create a worktree(no upstream no origin)(relative path) from a repo and switch to it',
            in_repo_from_local_no_worktrees(function()

            local random_str = git_worktree.get_root():sub(git_worktree.get_root():len()-4)
            local branch = "featB"
            local upstream = nil
            local path = "../git_worktree_test_repo_" .. branch .. "_" .. random_str
            git_worktree.create_worktree(path, branch)

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

            -- Check to make sure it is added to git worktree list
            assert.True(check_git_worktree_exists(expected_path))

            -- check to make sure branch/upstream is correct
            local correct_branch, correct_upstream = check_branch_upstream(branch, upstream)
            assert.True(correct_branch)
            assert.True(correct_upstream)

        end))

        it('can create a worktree(no upstream no origin)(absolute path) from a repo and switch to it',
            in_repo_from_local_no_worktrees(function()

            local random_str = git_worktree.get_root():sub(git_worktree.get_root():len()-4)
            local branch = "featB"
            local upstream = nil
            local path = "/tmp/git_worktree_test_repo_" .. branch .. "_" .. random_str

            git_worktree.create_worktree(path, branch)

            vim.fn.wait(
            10000,
            function()
                return completed_create and completed_switch
            end,
            1000
            )

            -- Check to make sure directory was switched
            assert.are.same(path, vim.loop.cwd())

            -- Check to make sure it is added to git worktree list
            assert.True(check_git_worktree_exists(path))

            -- check to make sure branch/upstream is correct
            local correct_branch, correct_upstream = check_branch_upstream(branch, upstream)
            assert.True(correct_branch)
            assert.True(correct_upstream)

        end))


    end)

    describe('Switch', function()

        it('from a bare repo with one worktree, able to switch to worktree (relative path)',
            in_bare_repo_from_origin_1_worktree(function()

            local path = "master"
            git_worktree.switch_worktree(path)

            vim.fn.wait(
            10000,
            function()
                return completed_switch
            end,
            1000
            )

            -- Check to make sure directory was switched
            assert.are.same(vim.loop.cwd(), git_worktree:get_root() .. Path.path.sep .. path)

        end))

        it('from a bare repo with one worktree, able to switch to worktree (absolute path)',
            in_bare_repo_from_origin_1_worktree(function()

            local path = git_worktree:get_root() .. Path.path.sep .. "master"
            git_worktree.switch_worktree(path)

            vim.fn.wait(
            10000,
            function()
                return completed_switch
            end,
            1000
            )

            -- Check to make sure directory was switched
            assert.are.same(vim.loop.cwd(), path)

        end))

        it('from a repo with one worktree, able to switch to worktree (relative path)',
            in_repo_from_origin_1_worktree(function()

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

            local expected_path = Path:new(git_worktree:get_root() .. '/'..path):normalize()

            -- Check to make sure directory was switched
            assert.are.same(vim.loop.cwd(), expected_path)

        end))

        it('from a repo with one worktree, able to switch to worktree (absolute path)',
            in_repo_from_origin_1_worktree(function()

            local random_str = git_worktree.get_root():sub(git_worktree.get_root():len()-4)
            local path = "/tmp/git_worktree_test_repo_featB_"..random_str
            git_worktree.switch_worktree(path)

            vim.fn.wait(
            10000,
            function()
                return completed_switch
            end,
            1000
            )

            -- Check to make sure directory was switched
            assert.are.same(vim.loop.cwd(), path)

        end))

        local get_current_file = function()
            return vim.api.nvim_buf_get_name(0)
        end

        it('in a featB worktree(bare) with file A open, switch to featC and switch to file A in other worktree',
            in_bare_repo_from_origin_2_worktrees(function()

            local featB_path = "featB"
            local featB_abs_path = git_worktree:get_root() .. Path.path.sep .. featB_path
            local featB_abs_A_path = featB_abs_path .. Path.path.sep .. "A.txt"

            local featC_path = "featC"
            local featC_abs_path = git_worktree:get_root() .. Path.path.sep .. featC_path
            local featC_abs_A_path = featC_abs_path .. Path.path.sep .. "A.txt"

            -- switch to featB worktree
            git_worktree.switch_worktree(featB_path)

            vim.fn.wait(
            10000,
            function()
                return completed_switch
            end,
            1000
            )

            -- open A file
            vim.cmd("e A.txt")
            -- make sure it is opensd
            assert.True(featB_abs_A_path == get_current_file())

            -- switch to featB worktree
            reset_variables()
            git_worktree.switch_worktree(featC_path)

            vim.fn.wait(
            10000,
            function()
                return completed_switch
            end,
            1000
            )

            -- make sure it switch to file in other tree
            assert.True(featC_abs_A_path == get_current_file())
        end))

        it('in a featB worktree(non bare) with file A open, switch to featC and switch to file A in other worktree',
            in_repo_from_origin_2_worktrees(function()

            local random_str = git_worktree.get_root():sub(git_worktree.get_root():len()-4)

            local featB_path = "../git_worktree_test_repo_featB_"..random_str
            local featB_abs_path = "/tmp/git_worktree_test_repo_featB_"..random_str
            local featB_abs_A_path = featB_abs_path.."/A.txt"

            local featC_path = "../git_worktree_test_repo_featC_"..random_str
            local featC_abs_path = "/tmp/git_worktree_test_repo_featC_"..random_str
            local featC_abs_A_path = featC_abs_path.."/A.txt"

            -- switch to featB worktree
            git_worktree.switch_worktree(featB_path)

            vim.fn.wait(
            10000,
            function()
                return completed_switch
            end,
            1000
            )

            -- open A file
            vim.cmd("e A.txt")
            -- make sure it is opensd
            assert.True(featB_abs_A_path == get_current_file())

            -- switch to featB worktree
            reset_variables()
            git_worktree.switch_worktree(featC_path)

            vim.fn.wait(
            10000,
            function()
                return completed_switch
            end,
            1000
            )

            -- make sure it switch to file in other tree
            assert.True(featC_abs_A_path == get_current_file())
        end))

        it("in a featB worktree(bare) with file B open, switch to featC and switch to worktree root in other worktree",
            in_bare_repo_from_origin_2_worktrees(function()

            local featB_path = "featB"
            local featB_abs_path = git_worktree:get_root() .. Path.path.sep .. featB_path
            local featB_abs_B_path = featB_abs_path .. Path.path.sep .. "B.txt"

            local featC_path = "featC"
            local featC_abs_path = git_worktree:get_root() .. Path.path.sep .. featC_path

            -- switch to featB worktree
            git_worktree.switch_worktree(featB_path)

            vim.fn.wait(
            10000,
            function()
                return completed_switch
            end,
            1000
            )

            -- open B file
            vim.cmd("e B.txt")
            -- make sure it is opensd
            assert.True(featB_abs_B_path == get_current_file())

            -- switch to featB worktree
            reset_variables()
            git_worktree.switch_worktree(featC_path)

            vim.fn.wait(
            10000,
            function()
                return completed_switch
            end,
            1000
            )

            -- make sure it switch to file in other tree
            assert.True(featC_abs_path == get_current_file())
        end))

        it("in a featB worktree(non bare) with file B open, switch to featC and switch to worktree root in other worktree",
            in_repo_from_origin_2_worktrees(function()

            local random_str = git_worktree.get_root():sub(git_worktree.get_root():len()-4)

            local featB_path = "../git_worktree_test_repo_featB_"..random_str
            local featB_abs_path = "/tmp/git_worktree_test_repo_featB_"..random_str
            local featB_abs_B_path = featB_abs_path.."/B.txt"

            local featC_path = "../git_worktree_test_repo_featC_"..random_str
            local featC_abs_path = "/tmp/git_worktree_test_repo_featC_"..random_str

            -- switch to featB worktree
            git_worktree.switch_worktree(featB_path)

            vim.fn.wait(
            10000,
            function()
                return completed_switch
            end,
            1000
            )

            -- open A file
            vim.cmd("e B.txt")
            -- make sure it is opensd
            assert.True(featB_abs_B_path == get_current_file())

            -- switch to featB worktree
            reset_variables()
            git_worktree.switch_worktree(featC_path)

            vim.fn.wait(
            10000,
            function()
                return completed_switch
            end,
            1000
            )

            -- make sure it switch to file in other tree
            assert.True(featC_abs_path == get_current_file())
        end))

        it('from a bare repo with two worktrees, able to switch to worktree with similar names (relative path)',
            in_bare_repo_from_origin_2_similar_named_worktrees(function()

            local path1 = "featB"
            local path2 = "featB-test"
            git_worktree.switch_worktree(path1)

            vim.fn.wait(
            10000,
            function()
                return completed_switch
            end,
            1000
            )
            reset_variables()

            -- Check to make sure directory was switched
            assert.are.same(vim.loop.cwd(), git_worktree:get_root() .. Path.path.sep .. path1)

            -- open A file
            vim.cmd("e A.txt")
            -- make sure it is opensd
            assert.True(vim.loop.cwd().."/A.txt" == get_current_file())

            git_worktree.switch_worktree(path2)

            vim.fn.wait(
            10000,
            function()
                return completed_switch
            end,
            1000
            )
            reset_variables()

            -- Check to make sure directory was switched
            assert.are.same(vim.loop.cwd(), git_worktree:get_root() .. Path.path.sep .. path2)
            -- Make sure file is switched
            assert.True(vim.loop.cwd().."/A.txt" == get_current_file())

            git_worktree.switch_worktree(path1)

            vim.fn.wait(
            10000,
            function()
                return completed_switch
            end,
            1000
            )

            -- Check to make sure directory was switched
            assert.are.same(vim.loop.cwd(), git_worktree:get_root() .. Path.path.sep .. path1)
            -- Make sure file is switched
            assert.True(vim.loop.cwd().."/A.txt" == get_current_file())

        end))

        it('from a bare repo with two worktrees, able to switch to worktree with similar names (absolute path)',
            in_bare_repo_from_origin_2_similar_named_worktrees(function()

            local path1 = git_worktree:get_root() .. Path.path.sep .. "featB"
            local path2 = git_worktree:get_root() .. Path.path.sep .. "featB-test"

            git_worktree.switch_worktree(path1)

            vim.fn.wait(
            10000,
            function()
                return completed_switch
            end,
            1000
            )
            reset_variables()

            -- Check to make sure directory was switched
            assert.are.same(vim.loop.cwd(), path1)

            -- open B file
            vim.cmd("e A.txt")
            -- make sure it is opensd
            assert.True(path1.."/A.txt" == get_current_file())

            git_worktree.switch_worktree(path2)

            vim.fn.wait(
            10000,
            function()
                return completed_switch
            end,
            1000
            )
            reset_variables()

            -- Check to make sure directory was switched
            assert.are.same(vim.loop.cwd(), path2)
            -- Make sure file is switched
            assert.True(path2.."/A.txt" == get_current_file())

            git_worktree.switch_worktree(path1)

            vim.fn.wait(
            10000,
            function()
                return completed_switch
            end,
            1000
            )

            -- Check to make sure directory was switched
            assert.are.same(vim.loop.cwd(), path1)
            -- Make sure file is switched
            assert.True(path1.."/A.txt" == get_current_file())

        end))

    end)

    describe('Delete', function()

        it('from a bare repo with one worktree, able to delete the worktree (relative path)',
            in_bare_repo_from_origin_1_worktree(function()

            local path = "master"
            git_worktree.delete_worktree(path)

            vim.fn.wait(
            10000,
            function()
                return completed_delete
            end,
            1000
            )

            -- Check to make sure it is added to git worktree list
            assert.False(check_git_worktree_exists(git_worktree:get_root() .. Path.path.sep .. path))

            -- Check to make sure directory was not switched
            assert.are.same(vim.loop.cwd(), git_worktree:get_root())

        end))

        it('from a bare repo with one worktree, able to delete the worktree (absolute path)',
            in_bare_repo_from_origin_1_worktree(function()

            local path = git_worktree:get_root() .. Path.path.sep .. "master"
            git_worktree.delete_worktree(path)

            vim.fn.wait(
            10000,
            function()
                return completed_delete
            end,
            1000
            )

            -- Check to make sure it is added to git worktree list
            assert.False(check_git_worktree_exists(path))

            -- Check to make sure directory was not switched
            assert.are.same(vim.loop.cwd(), git_worktree:get_root())

        end))

        it('from a repo with one worktree, able to delete the worktree (relative path)',
            in_repo_from_origin_1_worktree(function()

            local random_str = git_worktree.get_root():sub(git_worktree.get_root():len()-4)
            local path = "../git_worktree_test_repo_featB_"..random_str
            local absolute_path = "/tmp/git_worktree_test_repo_featB_"..random_str
            git_worktree.delete_worktree(path, true)

            vim.fn.wait(
            10000,
            function()
                return completed_delete
            end,
            1000
            )

            -- Check to make sure it is added to git worktree list
            assert.False(check_git_worktree_exists(absolute_path))

            -- Check to make sure directory was not switched
            assert.are.same(vim.loop.cwd(), git_worktree:get_root())

        end))

        it('from a repo with one worktree, able to delete the worktree (absolute path)',
            in_repo_from_origin_1_worktree(function()

            local random_str = git_worktree.get_root():sub(git_worktree.get_root():len()-4)
            local path = "/tmp/git_worktree_test_repo_featB_"..random_str
            git_worktree.delete_worktree(path, true)

            vim.fn.wait(
            10000,
            function()
                return completed_delete
            end,
            1000
            )

            -- Check to make sure it is added to git worktree list
            assert.False(check_git_worktree_exists(path))

            -- Check to make sure directory was not switched
            assert.are.same(vim.loop.cwd(), git_worktree:get_root())

        end))

    end)

    describe('Find Git Root Dir / Current Worktree on load', function()

        it('does not find the paths in a non git repo',
            in_non_git_repo(function()

            git_worktree:setup_git_info()
            assert.are.same(nil, git_worktree:get_root())
            assert.are.same(nil, git_worktree:get_current_worktree_path())

        end))

        it('finds the paths in a git repo',
            in_repo_from_origin_1_worktree(function()

            git_worktree:setup_git_info()
            assert.are.same(vim.loop.cwd(), git_worktree:get_root())
            assert.are.same(vim.loop.cwd(), git_worktree:get_current_worktree_path())

        end))

        it('finds the paths in a bare git repo',
            in_bare_repo_from_origin_1_worktree(function()

            git_worktree:setup_git_info()
            assert.are.same(vim.loop.cwd(), git_worktree:get_root())
            assert.are.same(vim.loop.cwd(), git_worktree:get_current_worktree_path())

        end))

        it('finds the paths from a git repo in a worktree',
            in_repo_from_origin_1_worktree(function()

            local expected_git_repo = git_worktree:get_root()
            -- switch to a worktree
            local random_str = git_worktree.get_root():sub(git_worktree.get_root():len()-4)
            local path = "/tmp/git_worktree_test_repo_featB_"..random_str
            git_worktree.switch_worktree(path)

            vim.fn.wait(
            10000,
            function()
                return completed_switch
            end,
            1000
            )

            -- Check to make sure directory was switched
            assert.are.same(vim.loop.cwd(), path)

            git_worktree:setup_git_info()
            assert.are.same(expected_git_repo, git_worktree:get_root())
            assert.are.same(vim.loop.cwd(), git_worktree:get_current_worktree_path())

        end))

        it('finds the paths from a bare git repo in a worktree',
            in_bare_repo_from_origin_1_worktree(function()

            local expected_git_repo = git_worktree:get_root()
            -- switch to a worktree
            local path = "master"
            git_worktree.switch_worktree(path)

            vim.fn.wait(
            10000,
            function()
                return completed_switch
            end,
            1000
            )

            -- Check to make sure directory was switched
            assert.are.same(vim.loop.cwd(), git_worktree:get_root() .. Path.path.sep .. path)

            git_worktree:setup_git_info()
            assert.are.same(expected_git_repo, git_worktree:get_root())
            assert.are.same(vim.loop.cwd(), git_worktree:get_current_worktree_path())

        end))
    end)

end)
