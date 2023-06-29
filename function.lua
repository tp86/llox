local makeenv = require("environment")
local executeblock = require("interpreter").executeblock

local functionmt

local function makefunc(declaration, closure, isinitializer)
  return setmetatable({
    closure = closure,
    declaration = declaration,
    isinitializer = isinitializer,
  }, functionmt)
end

functionmt = {
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
      if self.isinitializer then
        return self.closure:getat(0, "this")
      end
      return result.value
    end
    if self.isinitializer then return self.closure:getat(0, "this") end
  end,
  bind = function(self, instance)
    local environment = makeenv(self.closure)
    environment:define("this", instance)
    return makefunc(self.declaration, environment, self.isinitializer)
  end,
  __tostring = function(self)
    return "<fn " .. self.declaration.name.lexeme .. ">"
  end,
}
functionmt.__index = functionmt

return makefunc
