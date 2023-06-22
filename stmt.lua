local type_fields = {
  block = { "statements" },
  expression = { "expression" },
  ["if"] = { "condition", "thenbranch", "elsebranch" },
  print = { "expression" },
  var = { "name", "initializer" },
  ["while"] = { "condition", "body" },
}

local makeconstructors = require("base").makeconstructors

return makeconstructors("stmt", type_fields)
