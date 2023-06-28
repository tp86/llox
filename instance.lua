local e = require("error")

local instancemt = {
  type = "instance",
  get = function(self, name)
    local value = self.fields[name.lexeme]
    if value ~= nil then return value end

    local method = self.class:findmethod(name.lexeme)
    if method then return method:bind(self) end

    error(e.makeruntimeerror(name, "Undefined property '" .. name.lexeme .. "'."))
  end,
  set = function(self, name, value)
    self.fields[name.lexeme] = value
  end,
  __tostring = function(self)
    return self.class.name .. " instance"
  end,
}
instancemt.__index = instancemt

return function(class)
  return setmetatable({
    fields = {},
    class = class,
  }, instancemt)
end
