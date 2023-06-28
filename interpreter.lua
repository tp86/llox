local tt = require("tokentype")
local interpreter = require("visitor").make("interpreter")
local e = require("error")
local makeenv = require("environment")
local class = require("class")

local globals = makeenv()
local environment = globals
-- sentinel value for declaring uninitialized variables
-- needed for tracking variables in environment
local nilvalue = {}
local locals = {}

globals:define("clock", setmetatable({
  arity = function() return 0 end,
  call = function()
    return os.clock()
  end,
}, { __tostring = function() return "<native fn>" end }))

local function evaluate(expr)
  return expr:accept(interpreter)
end

local function execute(stmt)
  stmt:accept(interpreter)
end

local function executeblock(statements, newenvironment)
  local previousenvironment = environment
  local ok, err = pcall(function()
    environment = newenvironment
    for _, statement in ipairs(statements) do
      execute(statement)
    end
  end)
  environment = previousenvironment
  if not ok then
    error(err)
  end
end

local function istruthy(value)
  if value == nilvalue then return false end
  if type(value) == "boolean" then return value end
  return true
end

local function isequal(left, right)
  if left == nilvalue and right == nilvalue then return true end
  if left == nilvalue then return false end
  return left == right
end

local function checknumberoperands(operator, ...)
  local operands = { ... }
  local result = true
  for _, operand in ipairs(operands) do
    result = result and type(operand) == "number"
  end
  if not result then
    error(e.makeruntimeerror(operator, "Operand must be a number."))
  end
end

local function stringify(value)
  if value == nilvalue then return "nil" end
  if type(value) == "number" then
    local text = tostring(value)
    if text:sub(-2, -1) == ".0" then
      text = text:sub(1, -3)
    end
    return text
  end
  return tostring(value)
end

local function makereturn(value)
  return {
    type = "return",
    value = value,
  }
end

local function lookupvariable(name, expr)
  local distance = locals[expr]
  if distance then
    return environment:getat(distance, name.lexeme)
  else
    return globals:get(name)
  end
end

interpreter["expr.literal"] = function(expr)
  if expr.value == nil then return nilvalue end
  return expr.value
end
interpreter["expr.grouping"] = function(expr)
  return evaluate(expr.expression)
end
interpreter["expr.unary"] = function(expr)
  local right = evaluate(expr.right)
  if expr.operator.type == tt.MINUS then
    checknumberoperands(expr.operator, right)
    return -right
  elseif expr.operator.type == tt.BANG then
    return not istruthy(right)
  end
end
interpreter["expr.binary"] = function(expr)
  local left = evaluate(expr.left)
  local right = evaluate(expr.right)
  local op = expr.operator
  local optype = op.type
  if optype == tt.MINUS then
    checknumberoperands(op, left, right)
    return left - right
  end
  if optype == tt.SLASH then
    checknumberoperands(op, left, right)
    return left / right
  end
  if optype == tt.STAR then
    checknumberoperands(op, left, right)
    return left * right
  end
  if optype == tt.PLUS then
    if type(left) == "number" and type(right) == "number" then
      return left + right
    elseif type(left) == "string" and type(right) == "string" then
      return left .. right
    else
      error(e.makeruntimeerror(op, "Operands must be two numbers or two strings."))
    end
  end
  if optype == tt.GREATER then
    checknumberoperands(op, left, right)
    return left > right
  end
  if optype == tt.GREATER_EQUAL then
    checknumberoperands(op, left, right)
    return left >= right
  end
  if optype == tt.LESS then
    checknumberoperands(op, left, right)
    return left < right
  end
  if optype == tt.LESS_EQUAL then
    checknumberoperands(op, left, right)
    return left <= right
  end
  if optype == tt.BANG_EQUAL then return not isequal(left, right) end
  if optype == tt.EQUAL_EQUAL then return isequal(left, right) end
end
interpreter["expr.variable"] = function(expr)
  return lookupvariable(expr.name, expr)
end
interpreter["expr.assign"] = function(expr)
  local value = evaluate(expr.value)
  local distance = locals[expr]
  if distance then
    environment:assignat(distance, expr.name, value)
  else
    globals:assign(expr.name, value)
  end
  return value
end
interpreter["expr.logical"] = function(expr)
  local left = evaluate(expr.left)

  if expr.operator.type == tt.OR then
    if istruthy(left) then return left end
  else
    if not istruthy(left) then return left end
  end

  return evaluate(expr.right)
end
interpreter["expr.call"] = function(expr)
  local callee = evaluate(expr.callee)

  local arguments = {}
  for _, argument in ipairs(expr.arguments) do
    arguments[#arguments + 1] = evaluate(argument)
  end

  if not callee.call then
    error(e.makeruntimeerror(expr.paren, "Can only call functions and classes."))
  end

  if #arguments ~= callee:arity() then
    error(e.makeruntimeerror(expr.paren,
      ("Expected %s arguments but got %s."):format(callee:arity(), #arguments)))
  end

  return callee:call(arguments)
end
interpreter["stmt.expression"] = function(stmt)
  evaluate(stmt.expression)
end
interpreter["stmt.print"] = function(stmt)
  local value = evaluate(stmt.expression)
  print(stringify(value))
end
interpreter["stmt.var"] = function(stmt)
  local value = nilvalue
  if stmt.initializer then
    value = evaluate(stmt.initializer)
  end
  environment:define(stmt.name.lexeme, value)
end
interpreter["stmt.block"] = function(stmt)
  executeblock(stmt.statements, makeenv(environment))
end
interpreter["stmt.if"] = function(stmt)
  if istruthy(evaluate(stmt.condition)) then
    execute(stmt.thenbranch)
  elseif stmt.elsebranch then
    execute(stmt.elsebranch)
  end
end
interpreter["stmt.while"] = function(stmt)
  while istruthy(evaluate(stmt.condition)) do
    execute(stmt.body)
  end
end
interpreter["stmt.function"] = function(stmt)
  local func = require("function")(stmt, environment)
  environment:define(stmt.name.lexeme, func)
end
interpreter["stmt.return"] = function(stmt)
  local value
  if stmt.value then
    value = evaluate(stmt.value)
  end
  error(makereturn(value)) -- would be better to use coroutines to exit from arbitrarily nested statements in function
end
interpreter["stmt.class"] = function(stmt)
  environment:define(stmt.name.lexeme, nilvalue)

  local methods = {}
  for _, method in ipairs(stmt.methods) do
    local func = require("function")(method, environment)
    methods[method.name.lexeme] = func
  end

  local class = class(stmt.name.lexeme, methods) ---@diagnostic disable-line: redefined-local
  environment:assign(stmt.name, class)
end
interpreter["expr.get"] = function(expr)
  local object = evaluate(expr.object)
  if object.type == "instance" then
    return object:get(expr.name)
  end
  error(e.makeruntimeerror(expr.name, "Only instances have properties."))
end
interpreter["expr.set"] = function(expr)
  local object = evaluate(expr.object)

  if object.type ~= "instance" then
    error(e.makeruntimeerror(expr.name, "Only instances have fields."))
  end
  local value = evaluate(expr.value)
  object:set(expr.name, value)
  return value
end
interpreter["expr.this"] = function(expr)
  return lookupvariable(expr.keyword, expr)
end

local function resolve(expr, depth)
  locals[expr] = depth
end

return {
  interpret = function(statements)
    local ok, err = pcall(function()
      for _, statement in ipairs(statements) do
        execute(statement)
      end
    end)
    if not ok then
      ---[[
      if type(err) == "table" then
        --]]
        e.runtimeerror(err)
        ---[[
      else -- internal error, probably should be handled better (xpcall?)
        error(err)
      end
      --]]
    end
  end,
  executeblock = executeblock,
  resolve = resolve,
}
