local type_fields = {
  assign = { "name", "value" },
  binary = { "left", "operator", "right" },
  call = { "callee", "paren", "arguments" },
  get = { "object", "name" },
  grouping = { "expression" },
  literal = { "value" },
  logical = { "left", "operator", "right" },
  set = { "object", "name", "value" },
  unary = { "operator", "right" },
  variable = { "name" },
}

local makeconstructors = require("base").makeconstructors

return makeconstructors("expr", type_fields)
