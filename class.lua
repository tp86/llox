local instance = require("instance")

local classmt = {
  arity = function() return 0 end,
  call = function(self)
    local instance = instance(self) ---@diagnostic disable-line: redefined-local
    return instance
  end,
  findmethod = function(self, name)
    local method = self.methods[name]
    if method then return method end
  end,
  __tostring = function(self)
    return self.name
  end,
}
classmt.__index = classmt

return function(name, methods)
  return setmetatable({
    methods = methods,
    name = name,
  }, classmt)
end
