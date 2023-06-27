local instance = require("instance")

local classmt = {
  arity = function() return 0 end,
  call = function(self)
    local instance = instance(self) ---@diagnostic disable-line: redefined-local
    return instance
  end,
  __tostring = function(self)
    return self.name
  end,
}
classmt.__index = classmt

return function(name)
  return setmetatable({
    name = name,
  }, classmt)
end
