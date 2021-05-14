local git_worktree = require('git-worktree')
local Job = require('plenary.job')
local Path = require("plenary.path")

local M = {}

local get_os_command_output = function(cmd)
    local command = table.remove(cmd, 1)
    local stderr = {}
    local stdout, ret = Job:new({
        command = command,
        args = cmd,
        cwd = git_worktree.get_root(),
        on_stderr = function(_, data)
            table.insert(stderr, data)
        end
    }):sync()
    return stdout, ret, stderr
end

local prepare_origin_repo = function(dir)
    vim.api.nvim_exec('!cp -r tests/repo_origin/ /tmp/' .. dir, true)
    vim.api.nvim_exec('!mv /tmp/'..dir..'/.git-orig /tmp/'..dir..'/.git', true)
end

local prepare_bare_repo = function(dir, origin_dir)
    vim.api.nvim_exec('!git clone --bare /tmp/'..origin_dir..' /tmp/'..dir, true)
end

local fix_fetch_all = function()
    vim.api.nvim_exec('!git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"', true)
end

local prepare_repo = function(dir, origin_dir)
    vim.api.nvim_exec('!git clone /tmp/'..origin_dir..' /tmp/'..dir, true)
end

local random_string = function()
    math.randomseed(os.clock()^5)
    local ret = ""
    for _ = 1, 5 do
        local random_char = math.random(97,122)
        ret = ret .. string.char(random_char)
    end
    return ret
end

local change_dir = function(dir)
    vim.api.nvim_set_current_dir('/tmp/'..dir)
    git_worktree.set_worktree_root('/tmp/'..dir)
end

local cleanup_repos = function()
    vim.api.nvim_exec('silent !rm -rf /tmp/git_worktree_test*', true)
end

local create_worktree = function(folder_path, commitish)
    vim.api.nvim_exec('!git worktree add ' .. folder_path .. ' ' .. commitish, true)
end

local project_dir = vim.api.nvim_exec('pwd', true)

local reset_cwd = function()
    vim.cmd('cd ' .. project_dir)
    vim.api.nvim_set_current_dir(project_dir)
end

local config_git_worktree = function()
    git_worktree.setup({})
end

M.in_non_git_repo = function(cb)
    return function()
        local random_id = random_string()
        local dir = "git_worktree_test_repo_" .. random_id

        config_git_worktree()
        cleanup_repos()

        Path:new("/tmp/" .. dir):mkdir()
        change_dir(dir)

        local _, err = pcall(cb)

        reset_cwd()

        cleanup_repos()

        if err ~= nil then
            error(err)
        end

    end
end

M.in_bare_repo_from_origin_no_worktrees = function(cb)
    return function()
        local random_id = random_string()
        local origin_repo_dir = 'git_worktree_test_origin_repo_' .. random_id
        local bare_repo_dir = 'git_worktree_test_repo_' .. random_id

        config_git_worktree()
        cleanup_repos()

        prepare_origin_repo(origin_repo_dir)
        prepare_bare_repo(bare_repo_dir, origin_repo_dir)

        change_dir(bare_repo_dir)
        fix_fetch_all()

        local _, err = pcall(cb)

        reset_cwd()

        cleanup_repos()

        if err ~= nil then
            error(err)
        end

    end
end

M.in_repo_from_origin_no_worktrees = function(cb)
    return function()
        local random_id = random_string()
        local origin_repo_dir = 'git_worktree_test_origin_repo_' .. random_id
        local repo_dir = 'git_worktree_test_repo_' .. random_id

        config_git_worktree()
        cleanup_repos()

        prepare_origin_repo(origin_repo_dir)
        prepare_repo(repo_dir, origin_repo_dir)

        change_dir(repo_dir)

        local _, err = pcall(cb)

        reset_cwd()

        cleanup_repos()

        if err ~= nil then
            error(err)
        end

    end
end

M.in_repo_from_local_no_worktrees = function(cb)
    return function()
        local random_id = random_string()
        local local_repo_dir = 'git_worktree_test_origin_repo_' .. random_id

        config_git_worktree()
        cleanup_repos()

        prepare_origin_repo(local_repo_dir)

        change_dir(local_repo_dir)

        local _, err = pcall(cb)

        reset_cwd()

        cleanup_repos()

        if err ~= nil then
            error(err)
        end

    end
end

M.in_bare_repo_from_origin_1_worktree = function(cb)
    return function()
        local random_id = random_string()
        local origin_repo_dir = 'git_worktree_test_origin_repo_' .. random_id
        local bare_repo_dir = 'git_worktree_test_repo_' .. random_id

        config_git_worktree()
        cleanup_repos()

        prepare_origin_repo(origin_repo_dir)
        prepare_bare_repo(bare_repo_dir, origin_repo_dir)
        change_dir(bare_repo_dir)
        create_worktree('master','master')

        local _, err = pcall(cb)

        reset_cwd()

        cleanup_repos()

        if err ~= nil then
            error(err)
        end

    end
end

M.in_repo_from_origin_1_worktree = function(cb)
    return function()
        local random_id = random_string()
        local origin_repo_dir = 'git_worktree_test_origin_repo_' .. random_id
        local repo_dir = 'git_worktree_test_repo_' .. random_id
        local feat_dir = 'git_worktree_test_repo_featB_' .. random_id

        config_git_worktree()
        cleanup_repos()

        prepare_origin_repo(origin_repo_dir)
        prepare_repo(repo_dir, origin_repo_dir)
        change_dir(repo_dir)

        create_worktree('../'..feat_dir,'featB')

        local _, err = pcall(cb)

        reset_cwd()

        cleanup_repos()

        if err ~= nil then
            error(err)
        end

    end
end

M.in_bare_repo_from_origin_2_worktrees = function(cb)
    return function()
        local random_id = random_string()
        local origin_repo_dir = 'git_worktree_test_origin_repo_' .. random_id
        local bare_repo_dir = 'git_worktree_test_repo_' .. random_id

        config_git_worktree()
        cleanup_repos()

        prepare_origin_repo(origin_repo_dir)
        prepare_bare_repo(bare_repo_dir, origin_repo_dir)
        change_dir(bare_repo_dir)
        create_worktree('featB','featB')
        create_worktree('featC','featC')

        local _, err = pcall(cb)

        reset_cwd()

        cleanup_repos()

        if err ~= nil then
            error(err)
        end

    end
end

M.in_repo_from_origin_2_worktrees = function(cb)
    return function()
        local random_id = random_string()
        local origin_repo_dir = 'git_worktree_test_origin_repo_' .. random_id
        local repo_dir = 'git_worktree_test_repo_' .. random_id
        local featB_dir = 'git_worktree_test_repo_featB_' .. random_id
        local featC_dir = 'git_worktree_test_repo_featC_' .. random_id

        config_git_worktree()
        cleanup_repos()

        prepare_origin_repo(origin_repo_dir)
        prepare_repo(repo_dir, origin_repo_dir)
        change_dir(repo_dir)

        create_worktree('../'..featB_dir,'featB')
        create_worktree('../'..featC_dir,'featC')

        local _, err = pcall(cb)

        reset_cwd()

        cleanup_repos()

        if err ~= nil then
            error(err)
        end

    end
end

M.in_bare_repo_from_origin_2_similar_named_worktrees = function(cb)
    return function()
        local random_id = random_string()
        local origin_repo_dir = 'git_worktree_test_origin_repo_' .. random_id
        local bare_repo_dir = 'git_worktree_test_repo_' .. random_id

        config_git_worktree()
        cleanup_repos()

        prepare_origin_repo(origin_repo_dir)
        prepare_bare_repo(bare_repo_dir, origin_repo_dir)
        change_dir(bare_repo_dir)
        create_worktree('featB','featB')
        create_worktree('featB-test','featC')

        local _, err = pcall(cb)

        reset_cwd()

        cleanup_repos()

        if err ~= nil then
            error(err)
        end

    end
end

M.in_repo_from_origin_2_similar_named_worktrees = function(cb)
    return function()
        local random_id = random_string()
        local origin_repo_dir = 'git_worktree_test_origin_repo_' .. random_id
        local repo_dir = 'git_worktree_test_repo_' .. random_id
        local featB_dir = 'git_worktree_test_repo_featB_' .. random_id
        local featC_dir = 'git_worktree_test_repo_featB-test_' .. random_id

        config_git_worktree()
        cleanup_repos()

        prepare_origin_repo(origin_repo_dir)
        prepare_repo(repo_dir, origin_repo_dir)
        change_dir(repo_dir)

        create_worktree('../'..featB_dir,'featB')
        create_worktree('../'..featC_dir,'featC')

        local _, err = pcall(cb)

        reset_cwd()

        cleanup_repos()

        if err ~= nil then
            error(err)
        end

    end
end

local get_git_branches_upstreams = function()
    local output = get_os_command_output({
        "git", "for-each-ref", "--format", "'%(refname:short),%(upstream:short)'", "refs/heads"
    })
    return output
end

M.check_branch_upstream = function(branch, upstream)
    local correct_branch = false
    local correct_upstream = false
    local upstream_to_check

    if upstream == nil then
        upstream_to_check = ""
    else
        upstream_to_check = upstream .. '/' .. branch
    end

    local refs = get_git_branches_upstreams()
    for _, ref in ipairs(refs) do
        ref = ref:gsub("'","")
        local line = vim.split(ref, ",",true)
        local b = line[1]
        local u = line[2]

        if b == branch then
            correct_branch = true
            correct_upstream = ( u == upstream_to_check )
        end

    end

    return correct_branch, correct_upstream
end

local get_git_worktrees = function()
    local output = get_os_command_output({
        "git", "worktree", "list"
    })
    return output
end

M.check_git_worktree_exists = function(worktree_path)
    local worktree_exists = false

    local refs = get_git_worktrees()
    for _, line in ipairs(refs) do
        local worktree_line = {}
        for section in line:gmatch("%S+") do
            table.insert(worktree_line, section)
        end

        if worktree_path == worktree_line[1] then
            worktree_exists = true
        end

    end

    return worktree_exists
end

return M
