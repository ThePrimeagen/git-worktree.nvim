local Enum = function(tbl)
    return setmetatable(tbl, {
        __index = function(_, key)
            error(string.format("%s does not exist for this enum.", key))
        end,

        __newindex = function(t, key, value)
            error("Enums are immutable. You are not able to set new values")
        end,
    })
end

return {
    Operations = Enum({
        Create = "create",
        Switch = "switch",
        Delete = "delete",
    })
}



