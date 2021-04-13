local Status = {}

function Status:new(options)
    local obj = vim.tbl_extend('force', {
        -- What to do here?
    }, options or {})

    setmetatable(obj, self)
    self.__index = self

    return obj
end

function Status:reset(count)
    self.count = count
    self.idx = 0
end

function Status:_get_string(msg)
    return string.format("%d / %d: %s", self.idx, self.count, msg)
end

function Status:next_status(msg)
    self.idx = self.idx + 1
    print(self:_get_string(msg))
end

function Status:next_error(msg)
    self.idx = self.idx + 1
    error(self:_get_string(msg))
end

function Status:status(msg)
    print(self:_get_string(msg))
end

function Status:error(msg)
    error(self:_get_string(msg))
end

return Status
