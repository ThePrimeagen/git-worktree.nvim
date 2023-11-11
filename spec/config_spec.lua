local stub = require('luassert.stub')

describe('config', function()
    local notify_once = stub(vim, 'notify_once')
    local notify = stub(vim, 'notify')

    it('returns the default config', function()
        local Config = require('git-worktree.config')
        assert.truthy(Config.options.change_directory_command)
    end)

    it('can have configuration applied', function()
        local Config = require('git-worktree.config')
        Config.setup { change_directory_command = 'test' }
        assert.equals(Config.options.change_directory_command, 'test')
    end)

    it('No notifications at startup.', function()
        assert.stub(notify_once).was_not_called()
        assert.stub(notify).was_not_called()
    end)
end)
