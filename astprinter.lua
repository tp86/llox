local visitor = require("visitor")
local astprinter = visitor.make("astprinter")

local function parenthesize(name, ...)
  local builder = {}
  table.insert(builder, "(")
  table.insert(builder, name)
  for _, expr in ipairs { ... } do
    table.insert(builder, " ")
    table.insert(builder, expr:accept(astprinter))
  end
  table.insert(builder, ")")
  return table.concat(builder)
end

astprinter["expr.binary"] = function(expr)
  return parenthesize(expr.operator.lexeme, expr.left, expr.right)
end
astprinter["expr.grouping"] = function(expr)
  return parenthesize("group", expr.expression)
end
astprinter["expr.literal"] = function(expr)
  return tostring(expr.value)
end
astprinter["expr.unary"] = function(expr)
  return parenthesize(expr.operator.lexeme, expr.right)
end

return {
  print = function(expr)
    return expr:accept(astprinter)
  end,
}
