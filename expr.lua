local type_fields = {
  assign = { "name", "value" },
  binary = { "left", "operator", "right" },
  grouping = { "expression" },
  literal = { "value" },
  logical = { "left", "operator", "right" },
  unary = { "operator", "right" },
  variable = { "name" },
}

local makeconstructors = require("base").makeconstructors

return makeconstructors("expr", type_fields)
