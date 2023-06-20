local type_fields = {
  binary = { "left", "operator", "right" },
  grouping = { "expression" },
  literal = { "value" },
  unary = { "operator", "right" },
  variable = { "name" },
}

local makeconstructors = require("base").makeconstructors

return makeconstructors("expr", type_fields)
