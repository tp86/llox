local function makevisitor(name)
  return setmetatable({}, {
    __index = function(_, k)
      error(k .. " not implemented in " .. name)
    end
  })
end

local element = {
  accept = function(self, visitor)
    return visitor[self:visitby()](self)
  end,
  visitby = function(self)
    return self
  end,
}
element.__index = element

return {
  make = makevisitor,
  element = element,
}
