local instance = require("instance")

local classmt = {
  type = "class",
  arity = function(self)
    local initializer = self:findmethod("init")
    if initializer then return initializer:arity() end
    return 0
  end,
  call = function(self, arguments)
    local instance = instance(self) ---@diagnostic disable-line: redefined-local
    local initializer = self:findmethod("init")
    if initializer then
      initializer:bind(instance):call(arguments)
    end
    return instance
  end,
  findmethod = function(self, name)
    local method = self.methods[name]
    if method then return method end
    if self.superclass then
      return self.superclass:findmethod(name)
    end
  end,
  __tostring = function(self)
    return self.name
  end,
}
classmt.__index = classmt

return function(name, superclass, methods)
  return setmetatable({
    superclass = superclass,
    methods = methods,
    name = name,
  }, classmt)
end
