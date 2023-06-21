local type_fields = {
  block = { "statements" },
  expression = { "expression" },
  print = { "expression" },
  var = { "name", "initializer" },
}

local makeconstructors = require("base").makeconstructors

return makeconstructors("stmt", type_fields)
