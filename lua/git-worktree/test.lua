
local Path = require("plenary.path")
local path = Path:new(vim.loop.cwd(), "foo", "..", "..")


print(path:absolute())


