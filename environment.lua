local e = require("error")

local envmt = {
  define = function(self, name, value)
    self.values[name] = value
  end,
  get = function(self, name)
    local value = self.values[name.lexeme]
    if value ~= nil then
      return value
    end
    error(e.makeruntimeerror(name, "Undefined variable '" .. name.lexeme .. "'."))
  end,
  assign = function(self, name, value)
    -- we need to assign in correct environment, not current one
    local values = self.values
    while values and rawget(values, name.lexeme) == nil do
      values = (getmetatable(values) or {}).__index
    end
    if values then
      values[name.lexeme] = value
      return
    end
    error(e.makeruntimeerror(name, "Undefined variable '" .. name.lexeme .. "'."))
  end,
}
envmt.__index = envmt

return function(enclosing)
  return setmetatable({
    values = setmetatable({}, { __index = (enclosing or {}).values }),
  }, envmt)
end
