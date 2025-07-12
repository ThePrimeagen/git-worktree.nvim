
local Path = require("plenary.path")
local path = Path:new(vim.uv.cwd(), "foo", "..", "..")


print(path:absolute())


