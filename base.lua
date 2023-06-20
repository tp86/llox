local base = setmetatable({
  visitby = function(self)
    return self.type
  end,
}, require("visitor").element)
base.__index = base

local function makeconstructor(kind, name, fields)
  return function(...)
    local obj = {}
    for index, field_name in ipairs(fields) do
      obj[field_name] = select(index, ...)
    end
    obj.type = kind .. "." .. name
    return setmetatable(obj, base)
  end
end

local function makeconstructors(kind, type_fields)
  local constructors = {}
  for name, fields in pairs(type_fields) do
    constructors[name] = makeconstructor(kind, name, fields)
  end
  return constructors
end

return {
  makeconstructors = makeconstructors,
}
