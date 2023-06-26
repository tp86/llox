local makeenv = require("environment")
local executeblock = require("interpreter").executeblock

local functionmt = {
  arity = function(self)
    return #self.declaration.params
  end,
  call = function(self, arguments)
    local environment = makeenv(self.closure)
    for i, param in ipairs(self.declaration.params) do
      environment:define(param.lexeme, arguments[i])
    end

    local ok, result = pcall(function()
      executeblock(self.declaration.body, environment)
    end)
    if not ok and type(result) == "table" and result.type == "return" then
      return result.value
    end
  end,
  __tostring = function(self)
    return "<fn " .. self.declaration.name.lexeme .. ">"
  end,
}
functionmt.__index = functionmt

return function(declaration, closure)
  return setmetatable({
    closure = closure,
    declaration = declaration,
  }, functionmt)
end
