local tt = require("tokentype")
local expr = require("expr")
local stmt = require("stmt")
local e = require("error")

local function parse(tokens)
  local current = 1

  local function peek()
    return tokens[current]
  end

  local function previous()
    return tokens[current - 1]
  end

  local function isatend()
    return peek().type == tt.EOF
  end

  local function check(type)
    if isatend() then return false end
    return peek().type == type
  end

  local function advance()
    if not isatend() then current = current + 1 end
    return previous()
  end

  local function match(types)
    for _, type in ipairs(types) do
      if check(type) then
        advance()
        return true
      end
    end
    return false
  end

  local function parseerror(token, message)
    e.error(token, message)
    return "PARSE_ERROR"
  end

  local function consume(tokentype, message)
    if check(tokentype) then return advance() end
    error(parseerror(peek(), message))
  end

  local function synchronize()
    advance()
    while not isatend() do
      if previous().type == tt.SEMICOLON then return end
      local statementbeginnings = {
        tt.CLASS,
        tt.FUN,
        tt.VAR,
        tt.FOR,
        tt.IF,
        tt.WHILE,
        tt.PRINT,
        tt.RETURN,
      }
      if statementbeginnings[peek().type] then return end
      advance()
    end
  end

  local function leftassociativebinary(operators, higherprecedencerule)
    return function()
      local expression = higherprecedencerule()

      while match(operators) do
        local operator = previous()
        local right = higherprecedencerule()
        expression = expr.binary(expression, operator, right)
      end

      return expression
    end
  end

  local expression

  local function primary()
    if match { tt.FALSE } then return expr.literal(false) end
    if match { tt.TRUE } then return expr.literal(true) end
    if match { tt.NIL } then return expr.literal(nil) end
    if match { tt.NUMBER, tt.STRING } then return expr.literal(previous().literal) end
    if match { tt.IDENTIFIER } then return expr.variable(previous()) end
    if match { tt.LEFT_PAREN } then
      local expression = expression() ---@diagnostic disable-line: redefined-local
      consume(tt.RIGHT_PAREN, "Expect ')' after expression.")
      return expr.grouping(expression)
    end
    error(parseerror(peek(), "Expect expression."))
  end

  local function unary()
    if match { tt.BANG, tt.MINUS } then
      local operator = previous()
      local right = unary()
      return expr.unary(operator, right)
    end

    return primary()
  end

  local factor = leftassociativebinary({ tt.SLASH, tt.STAR }, unary)
  local term = leftassociativebinary({ tt.MINUS, tt.PLUS }, factor)
  local comparison = leftassociativebinary({ tt.GREATER, tt.GREATER_EQUAL, tt.LESS, tt.LESS_EQUAL }, term)
  local equality = leftassociativebinary({ tt.BANG_EQUAL, tt.EQUAL_EQUAL }, comparison)

  expression = function()
    return equality()
  end

  local function printstatement()
    local value = expression()
    consume(tt.SEMICOLON, "Expect ';' after value.")
    return stmt.print(value)
  end

  local function expressionstatement()
    local expression = expression() ---@diagnostic disable-line:redefined-local
    consume(tt.SEMICOLON, "Expect ';' after expression.")
    return stmt.expression(expression)
  end

  local function statement()
    if match { tt.PRINT } then return printstatement() end
    return expressionstatement()
  end

  local function vardeclaration()
    local name = consume(tt.IDENTIFIER, "Expect variable name.")
    local initializer
    if match { tt.EQUAL } then
      initializer = expression()
    end
    consume(tt.SEMICOLON, "Expect ';' after variable declaration.")
    return stmt.var(name, initializer)
  end

  local function declaration()
    local ok, result = pcall(function()
      if match { tt.VAR } then return vardeclaration() end
      return statement()
    end)
    if ok then
      return result
    else
      if result == "PARSE_ERROR" then
        synchronize()
      end
    end
  end

  local statements = {}
  while not isatend() do
    statements[#statements + 1] = declaration()
  end
  return statements
end

return parse
