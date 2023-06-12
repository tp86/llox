local tt = require("tokentype")
local token = require("token")
local e = require("error")

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

  local function addtoken(type, literal)
    local text = source:sub(start, current)
    tokens[#tokens+1] = token(type, text, literal, line)
  end

  local function scantoken()
    local c = advance()
    if c == "(" then addtoken(tt.LEFT_PAREN)
    elseif c == ")" then addtoken(tt.RIGHT_PAREN)
    elseif c == "{" then addtoken(tt.LEFT_BRACE)
    elseif c == "}" then addtoken(tt.RIGHT_BRACE)
    elseif c == "," then addtoken(tt.COMMA)
    elseif c == "." then addtoken(tt.DOT)
    elseif c == "-" then addtoken(tt.MINUS)
    elseif c == "+" then addtoken(tt.PLUS)
    elseif c == ";" then addtoken(tt.SEMICOLON)
    elseif c == "*" then addtoken(tt.STAR)
    else e.error(line, "Unexpected character.")
    end
  end

  while not isatend() do
    -- beginning of the next lexeme
    start = current
    scantoken()
  end

  tokens[#tokens+1] = token(tt.EOF, "", nil, line)
  return tokens
end

return scan
