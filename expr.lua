local exprbase = {
  accept = function(self, visitor)
    return visitor[self.type](self)
  end,
}
exprbase.__index = exprbase

local function makeexprconstructor(name, params)
  return function(...)
    local tbl = {}
    for index, param_name in ipairs(params) do
      tbl[param_name] = select(index, ...)
    end
    tbl.type = name .. "_expr"
    return setmetatable(tbl, exprbase)
  end
end

return {
  binary = makeexprconstructor("binary", {"left", "operator", "right"}),
  grouping = makeexprconstructor("grouping", {"expression"}),
  literal = makeexprconstructor("literal", {"value"}),
  unary = makeexprconstructor("unary", {"operator", "right"}),
}
