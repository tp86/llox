local type_fields = {
  expression = { "expression" },
  print = { "expression" },
  var = { "name", "initializer" },
}

local makeconstructors = require("base").makeconstructors

return makeconstructors("stmt", type_fields)
