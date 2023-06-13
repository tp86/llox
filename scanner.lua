local tt = require("tokentype")
local token = require("token")
local e = require("error")

local keywords = {
  ["and"] = tt.AND,
  ["class"] = tt.CLASS,
  ["else"] = tt.ELSE,
  ["false"] = tt.FALSE,
  ["for"] = tt.FOR,
  ["fun"] = tt.FUN,
  ["if"] = tt.IF,
  ["nil"] = tt.NIL,
  ["or"] = tt.OR,
  ["print"] = tt.PRINT,
  ["return"] = tt.RETURN,
  ["super"] = tt.SUPER,
  ["this"] = tt.THIS,
  ["true"] = tt.TRUE,
  ["var"] = tt.VAR,
  ["while"] = tt.WHILE,
}

local function scan(source)
  local tokens = {}
  local start = 1
  local current = 1
  local line = 1

  local function isatend()
    return current >= #source + 1
  end

  local function advance()
    local c = source:sub(current, current)
    current = current + 1
    return c
  end

  local function match(expected)
    if isatend() then return false end
    if source:sub(current, current) ~= expected then return false end
    current = current + 1
    return true
  end

  local function peek()
    if isatend() then return "\0" end
    return source:sub(current, current)
  end

  local function peeknext()
    if current >= #source then return "\0" end
    return source:sub(current + 1, current + 1)
  end

  local function isdigit(char)
    return char >= "0" and char <= "9"
  end

  local function isalpha(char)
    return (char >= "a" and char <= "z") or
        (char >= "A" and char <= "Z") or
        char == "_"
  end

  local function isalphanumeric(char)
    return isalpha(char) or isdigit(char)
  end

  local function addtoken(type, literal)
    local text = source:sub(start, current - 1)
    tokens[#tokens + 1] = token(type, text, literal, line)
  end

  local function string()
    while peek() ~= '"' and not isatend() do
      if peek() == "\n" then line = line + 1 end
      advance()
    end
    if isatend() then
      e.error(line, "Unterminated string.")
      return
    end
    advance() -- the closing "
    -- trim the surrounding quotes
    local value = source:sub(start + 1, current - 2)
    addtoken(tt.STRING, value)
  end

  local function number()
    while isdigit(peek()) do advance() end
    -- fractional part
    if peek() == "." and isdigit(peeknext()) then
      advance() -- consume the .
      while isdigit(peek()) do advance() end
    end
    addtoken(tt.NUMBER, tonumber(source:sub(start, current - 1)))
  end

  local function identifier()
    while isalphanumeric(peek()) do advance() end
    local text = source:sub(start, current - 1)
    local type = keywords[text] or tt.IDENTIFIER
    addtoken(type)
  end

  local function scantoken()
    local c = advance()
    if c == "(" then
      addtoken(tt.LEFT_PAREN)
    elseif c == ")" then
      addtoken(tt.RIGHT_PAREN)
    elseif c == "{" then
      addtoken(tt.LEFT_BRACE)
    elseif c == "}" then
      addtoken(tt.RIGHT_BRACE)
    elseif c == "," then
      addtoken(tt.COMMA)
    elseif c == "." then
      addtoken(tt.DOT)
    elseif c == "-" then
      addtoken(tt.MINUS)
    elseif c == "+" then
      addtoken(tt.PLUS)
    elseif c == ";" then
      addtoken(tt.SEMICOLON)
    elseif c == "*" then
      addtoken(tt.STAR)
    elseif c == "!" then
      if match("=") then
        addtoken(tt.BANG_EQUAL)
      else
        addtoken(tt.BANG)
      end
    elseif c == "=" then
      if match("=") then
        addtoken(tt.EQUAL_EQUAL)
      else
        addtoken(tt.EQUAL)
      end
    elseif c == "<" then
      if match("=") then
        addtoken(tt.LESS_EQUAL)
      else
        addtoken(tt.LESS)
      end
    elseif c == ">" then
      if match("=") then
        addtoken(tt.GREATER_EQUAL)
      else
        addtoken(tt.GREATER)
      end
    elseif c == "/" then
      if match("/") then
        -- comment goes until the end of then line
        while peek() ~= "\n" and not isatend() do advance() end
      else
        addtoken(tt.SLASH)
      end
    elseif c == " " or
        c == "\r" or
        c == "\t" then
      -- ignore whitespace
    elseif c == "\n" then
      line = line + 1
    elseif c == '"' then
      string()
    elseif isdigit(c) then
      number()
    elseif isalpha(c) then
      identifier()
    else
      e.error(line, "Unexpected character.")
    end
  end

  while not isatend() do
    -- beginning of the next lexeme
    start = current
    scantoken()
  end

  tokens[#tokens + 1] = token(tt.EOF, "", nil, line)
  return tokens
end

return scan
