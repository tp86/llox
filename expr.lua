local visitor = require("visitor")
local exprbase = setmetatable({
  visitby = function(self)
    return self.type
  end,
}, visitor.element)
exprbase.__index = exprbase

local function makeexprconstructor(name, params)
  return function(...)
    local expr = {}
    for index, param_name in ipairs(params) do
      expr[param_name] = select(index, ...)
    end
    expr.type = name .. "_expr"
    return setmetatable(expr, exprbase)
  end
end

return {
  binary = makeexprconstructor("binary", {"left", "operator", "right"}),
  grouping = makeexprconstructor("grouping", {"expression"}),
  literal = makeexprconstructor("literal", {"value"}),
  unary = makeexprconstructor("unary", {"operator", "right"}),
}
