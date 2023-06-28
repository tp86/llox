local resolver = require("visitor").make("resolver")
local e = require("error")
local interpreter = require("interpreter")

local scopes = {}

local functiontype = {
  NONE = "NONE",
  FUNCTION = "FUNCTION",
  METHOD = "METHOD",
}

local classtype = {
  NONE = "NONE",
  CLASS = "CLASS",
}

local currentfunction = functiontype.NONE

local currentclass = classtype.NONE

local function resolve(node)
  node:accept(resolver)
end

local function resolvestatements(statements)
  for _, statement in ipairs(statements) do
    resolve(statement)
  end
end

local function beginscope()
  table.insert(scopes, {})
end

local function endscope()
  table.remove(scopes)
end

local function declare(name)
  if #scopes == 0 then return end

  local scope = scopes[#scopes]
  if scope[name.lexeme] ~= nil then
    e.error(name, "Already a variable with this name in this scope.")
  end
  scope[name.lexeme] = false
end

local function define(name)
  if #scopes == 0 then return end

  local scope = scopes[#scopes]
  scope[name.lexeme] = true
end

local function resolvelocal(expr, name)
  for i = #scopes, 1, -1 do
    if scopes[i][name.lexeme] ~= nil then
      interpreter.resolve(expr, #scopes - i)
    end
  end
end

local function resolvefunction(func, type)
  local enclosingfunction = currentfunction
  currentfunction = type
  beginscope()
  for _, param in ipairs(func.params) do
    declare(param)
    define(param)
  end
  resolvestatements(func.body)
  endscope()
  currentfunction = enclosingfunction
end

resolver["stmt.block"] = function(stmt)
  beginscope()
  resolvestatements(stmt.statements)
  endscope()
end
resolver["stmt.var"] = function(stmt)
  declare(stmt.name)
  if stmt.initializer then
    resolve(stmt.initializer)
  end
  define(stmt.name)
end
resolver["expr.variable"] = function(expr)
  if (scopes[#scopes] or {})[expr.name.lexeme] == false then
    e.error(expr.name, "Can't read local variable in its own initializer.")
  end
  resolvelocal(expr, expr.name)
end
resolver["expr.assign"] = function(expr)
  resolve(expr.value)
  resolvelocal(expr, expr.name)
end
resolver["stmt.function"] = function(stmt)
  declare(stmt.name)
  define(stmt.name)
  resolvefunction(stmt, functiontype.FUNCTION)
end
resolver["stmt.expression"] = function(stmt)
  resolve(stmt.expression)
end
resolver["stmt.if"] = function(stmt)
  resolve(stmt.condition)
  resolve(stmt.thenbranch)
  if stmt.elsebranch then
    resolve(stmt.elsebranch)
  end
end
resolver["stmt.print"] = function(stmt)
  resolve(stmt.expression)
end
resolver["stmt.return"] = function(stmt)
  if currentfunction == functiontype.NONE then
    e.error(stmt.keyword, "Can't return from top-level code.")
  end
  if stmt.value then
    resolve(stmt.value)
  end
end
resolver["stmt.while"] = function(stmt)
  resolve(stmt.condition)
  resolve(stmt.body)
end
resolver["expr.binary"] = function(expr)
  resolve(expr.left)
  resolve(expr.right)
end
resolver["expr.call"] = function(expr)
  resolve(expr.callee)
  for _, argument in ipairs(expr.arguments) do
    resolve(argument)
  end
end
resolver["expr.grouping"] = function(expr)
  resolve(expr.expression)
end
resolver["expr.literal"] = function(expr)
end
resolver["expr.logical"] = resolver["expr.binary"]
resolver["expr.unary"] = function(expr)
  resolve(expr.right)
end
resolver["stmt.class"] = function(stmt)
  local enclosingclass = currentclass
  currentclass = classtype.CLASS

  declare(stmt.name)
  define(stmt.name)

  beginscope()
  scopes[#scopes].this = true

  for _, method in ipairs(stmt.methods) do
    local declaration = functiontype.METHOD
    resolvefunction(method, declaration)
  end

  endscope()
  currentclass = enclosingclass
end
resolver["expr.get"] = function(expr)
  resolve(expr.object)
end
resolver["expr.set"] = function(expr)
  resolve(expr.value)
  resolve(expr.object)
end
resolver["expr.this"] = function(expr)
  if currentclass == classtype.NONE then
    e.error(expr.keyword, "Can't use 'this' outside of a class.")
  end
  resolvelocal(expr, expr.keyword)
end

return resolvestatements
