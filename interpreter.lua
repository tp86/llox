local tt = require("tokentype")
local visitor = require("visitor")
local interpreter = visitor.make("interpreter")
local e = require("error")

local function evaluate(expr)
  return expr:accept(interpreter)
end

local function istruthy(value)
  if value == nil then return false end
  if type(value) == "boolean" then return value end
  return true
end

local function isequal(left, right)
  if left == nil and right == nil then return true end
  if left == nil then return false end
  return left == right
end

local function runtimeerror(token, message)
  return {
    token = token,
    message = message,
  }
end

local function checknumberoperands(operator, ...)
  local operands = { ... }
  local result = true
  for _, operand in ipairs(operands) do
    result = result and type(operand) == "number"
  end
  if not result then
    error(runtimeerror(operator, "Operand must be a number."))
  end
end

local function stringify(value)
  if value == nil then return "nil" end
  if type(value) == "number" then
    local text = tostring(value)
    if text:sub(-2, -1) == ".0" then
      text = text:sub(1, -3)
    end
    return text
  end
  return tostring(value)
end

interpreter.literal_expr = function(expr)
  return expr.value
end
interpreter.grouping_expr = function(expr)
  return evaluate(expr.expression)
end
interpreter.unary_expr = function(expr)
  local right = evaluate(expr.right)
  if expr.operator.type == tt.MINUS then
    checknumberoperands(expr.operator, right)
    return -right
  elseif expr.operator.type == tt.BANG then
    return not istruthy(right)
  end
end
interpreter.binary_expr = function(expr)
  local left = evaluate(expr.left)
  local right = evaluate(expr.right)
  local optype = expr.operator.type
  if optype == tt.MINUS then
    checknumberoperands(expr.operator, left, right)
    return left - right
  elseif optype == tt.SLASH then
    checknumberoperands(expr.operator, left, right)
    return left / right
  elseif optype == tt.STAR then
    checknumberoperands(expr.operator, left, right)
    return left * right
  elseif optype == tt.PLUS then
    if type(left) == "number" and type(right) == "number" then
      return left + right
    elseif type(left) == "string" and type(right) == "string" then
      return left .. right
    else
      error(runtimeerror(expr.operator, "Operands must be two numbers or two strings."))
    end
  elseif optype == tt.GREATER then
    checknumberoperands(expr.operator, left, right)
    return left > right
  elseif optype == tt.GREATER_EQUAL then
    checknumberoperands(expr.operator, left, right)
    return left >= right
  elseif optype == tt.LESS then
    checknumberoperands(expr.operator, left, right)
    return left < right
  elseif optype == tt.LESS_EQUAL then
    checknumberoperands(expr.operator, left, right)
    return left <= right
  elseif optype == tt.BANG_EQUAL then return not isequal(left, right)
  elseif optype == tt.EQUAL_EQUAL then return isequal(left, right)
  end
end

return {
  interpret = function(expr)
    local ok, result = pcall(evaluate, expr)
    if ok then
      print(stringify(result))
    else
      e.runtimeerror(result)
    end
  end,
}
