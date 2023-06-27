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

  local function finishcall(callee)
    local arguments = {}
    if not check(tt.RIGHT_PAREN) then
      repeat
        if #arguments >= 255 then
          parseerror(peek(), "Can't have more than 255 arguments.")
        end
        arguments[#arguments + 1] = expression()
      until not match { tt.COMMA }
    end

    local paren = consume(tt.RIGHT_PAREN, "Expect ')' after arguments.")

    return expr.call(callee, paren, arguments)
  end

  local function call()
    local expression = primary() ---@diagnostic disable-line: redefined-local

    while true do
      if match { tt.LEFT_PAREN } then
        expression = finishcall(expression)
      elseif match { tt.DOT } then
        local name  = consume(tt.IDENTIFIER, "Expect property name after '.'.")
        expression = expr.get(expression, name)
      else
        break
      end
    end

    return expression
  end

  local function unary()
    if match { tt.BANG, tt.MINUS } then
      local operator = previous()
      local right = unary()
      return expr.unary(operator, right)
    end

    return call()
  end

  local factor = leftassociativebinary({ tt.SLASH, tt.STAR }, unary)
  local term = leftassociativebinary({ tt.MINUS, tt.PLUS }, factor)
  local comparison = leftassociativebinary({ tt.GREATER, tt.GREATER_EQUAL, tt.LESS, tt.LESS_EQUAL }, term)
  local equality = leftassociativebinary({ tt.BANG_EQUAL, tt.EQUAL_EQUAL }, comparison)

  local function logicalop(optype, higherprecedencerule)
    return function()
      local expression = higherprecedencerule() ---@diagnostic disable-line: redefined-local

      while match { optype } do
        local operator = previous()
        local right = higherprecedencerule()
        expression = expr.logical(expression, operator, right)
      end

      return expression
    end
  end

  local and_ = logicalop(tt.AND, equality)
  local or_ = logicalop(tt.OR, and_)

  local function assignment()
    local expression = or_() ---@diagnostic disable-line: redefined-local

    if match { tt.EQUAL } then
      local equals = previous()
      local value = assignment() -- right-associativity

      if expression.type == "expr.variable" then
        local name = expression.name
        return expr.assign(name, value)
      elseif expression.type == "expr.get" then
        return expr.set(expression.object, expression.name, value)
      end

      parseerror(equals, "Invalid assignment target.")
    end

    return expression
  end

  expression = function()
    return assignment()
  end

  local declaration, vardeclaration, statement

  local function block()
    local statements = {}

    while not check(tt.RIGHT_BRACE) and not isatend() do
      statements[#statements + 1] = declaration()
    end

    consume(tt.RIGHT_BRACE, "Expect '}' after block.")
    return statements
  end

  local function ifstatement()
    consume(tt.LEFT_PAREN, "Expect '(' after 'if'.")
    local condition = expression()
    consume(tt.RIGHT_PAREN, "Expect ')' after if condition.")

    local thenbranch, elsebranch = (statement()) ---@diagnostic disable-line: unbalanced-assignments
    if match { tt.ELSE } then
      elsebranch = statement()
    end

    return stmt["if"](condition, thenbranch, elsebranch)
  end

  local function printstatement()
    local value = expression()
    consume(tt.SEMICOLON, "Expect ';' after value.")
    return stmt.print(value)
  end

  local function whilestatement()
    consume(tt.LEFT_PAREN, "Expect '(' after 'while'.")
    local condition = expression()
    consume(tt.RIGHT_PAREN, "Expect ')' after condition.")
    local body = statement()
    return stmt["while"](condition, body)
  end

  local function expressionstatement()
    local expression = expression() ---@diagnostic disable-line:redefined-local
    consume(tt.SEMICOLON, "Expect ';' after expression.")
    return stmt.expression(expression)
  end

  local function forstatement() -- XXX syntactic sugar implementation
    consume(tt.LEFT_PAREN, "Expect '(' after 'for'.")

    local initializer
    if match { tt.SEMICOLON } then
    elseif match { tt.VAR } then
      initializer = vardeclaration()
    else
      initializer = expressionstatement()
    end

    local condition
    if not check(tt.SEMICOLON) then
      condition = expression()
    end
    consume(tt.SEMICOLON, "Expect ';' after loop condition.")

    local increment
    if not check(tt.RIGHT_PAREN) then
      increment = expression()
    end
    consume(tt.RIGHT_PAREN, "Expect ')' after for clauses.")

    local body = statement()

    if increment then
      body = stmt.block({ body, stmt.expression(increment) })
    end

    if not condition then condition = expr.literal(true) end
    body = stmt["while"](condition, body)

    if initializer then
      body = stmt.block({ initializer, body })
    end

    return body
  end

  local function returnstatement()
    local keyword = previous()
    local value
    if not check(tt.SEMICOLON) then
      value = expression()
    end
    consume(tt.SEMICOLON, "Expect ';' after return value.")
    return stmt["return"](keyword, value)
  end

  statement = function()
    if match { tt.FOR } then return forstatement() end
    if match { tt.IF } then return ifstatement() end
    if match { tt.PRINT } then return printstatement() end
    if match { tt.RETURN } then return returnstatement() end
    if match { tt.WHILE } then return whilestatement() end
    if match { tt.LEFT_BRACE } then return stmt.block(block()) end
    return expressionstatement()
  end

  vardeclaration = function()
    local name = consume(tt.IDENTIFIER, "Expect variable name.")
    local initializer
    if match { tt.EQUAL } then
      initializer = expression()
    end
    consume(tt.SEMICOLON, "Expect ';' after variable declaration.")
    return stmt.var(name, initializer)
  end

  local function fundeclaration(kind)
    local name = consume(tt.IDENTIFIER, "Expect " .. kind .. " name.")
    consume(tt.LEFT_PAREN, "Expect '(' after " .. kind .. " name.")
    local parameters = {}
    if not check(tt.RIGHT_PAREN) then
      repeat
        if #parameters >= 255 then
          parseerror(peek(), "Can't have more than 255 parameters.")
        end
        parameters[#parameters + 1] = consume(tt.IDENTIFIER, "Expect parameter name.")
      until not match { tt.COMMA }
    end
    consume(tt.RIGHT_PAREN, "Expect ')' after parameters.")
    consume(tt.LEFT_BRACE, "Expect '{' before " .. kind .. " body.")
    local body = block()
    return stmt["function"](name, parameters, body)
  end

  local function classdeclaration()
    local name = consume(tt.IDENTIFIER, "Expect class name.")
    consume(tt.LEFT_BRACE, "Expect '{' before class body.")

    local methods = {}
    while not check(tt.RIGHT_BRACE) and not isatend() do
      methods[#methods+1] = fundeclaration("method")
    end

    consume(tt.RIGHT_BRACE, "Expect '}' after class body.")
    return stmt.class(name, methods)
  end

  declaration = function()
    local ok, result = pcall(function()
      if match { tt.CLASS } then return classdeclaration() end
      if match { tt.FUN } then return fundeclaration("function") end
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
