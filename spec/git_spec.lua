local git_harness = require("util.git_harness")
local gwt_git = require("git-worktree.git")
local Status = require("git-worktree.status")

local status = Status:new()

describe("git-worktree git operations", function()
    describe("finds git toplevel in normal repo", function()
        before_each(function()
            repo_dir = git_harness.prepare_repo()
        end)
        it("Public API is available after setup.", function()
            local ret_git_dir = gwt_git.find_git_dir()
            assert.are.same(ret_git_dir, repo_dir)
        end)
    end)

    describe("finds git toplevel in bare repo", function()
        before_each(function()
            repo_dir = git_harness.prepare_repo_bare()
        end)
        it("no toplevel in a bare repo", function()
            local ret_git_dir = gwt_git.find_git_dir()
            assert.are.same(ret_git_dir, nil)
        end)
    end)

    describe("finds git toplevel in worktree repo", function()
        before_each(function()
            repo_dir = git_harness.prepare_repo_worktree()
        end)
        it("Public API is available after setup.", function()
            local ret_git_dir = gwt_git.find_git_dir()
            status:log().info("ret_git_dir: " .. ret_git_dir .. ".")
            status:log().info("repo_dir   : " .. repo_dir .. ".")
            assert.are.same(ret_git_dir, repo_dir)
        end)
    end)
end)
