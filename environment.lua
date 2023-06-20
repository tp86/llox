local e = require("error")

local envmt = {
  define = function(self, name, value)
    self.values[name] = value
  end,
  get = function(self, name)
    local value = self.values[name.lexeme]
    if value then
      return value
    end
    error(e.makeruntimeerror(name, "Undefined variable '" .. name.lexeme .. "'."))
  end,
}
envmt.__index = envmt

return function()
  return setmetatable({
    values = {},
  }, envmt)
end
