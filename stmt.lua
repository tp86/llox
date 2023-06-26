local type_fields = {
  block = { "statements" },
  expression = { "expression" },
  ["function"] = { "name", "params", "body" },
  ["if"] = { "condition", "thenbranch", "elsebranch" },
  print = { "expression" },
  ["return"] = { "keyword", "value" },
  var = { "name", "initializer" },
  ["while"] = { "condition", "body" },
}

local makeconstructors = require("base").makeconstructors

return makeconstructors("stmt", type_fields)
