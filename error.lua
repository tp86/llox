local tt = require("tokentype")

local haderror = false
local hadruntimeerror = false

local function report(line, where, message)
  io.stderr:write(("[line %s] Error%s: %s\n"):format(line, where, message))
  haderror = true
end

local function error(object, message)
  if type(object) == "string" then
    -- object is line, scanner error
    report(object, "", message)
  elseif type(object) == "table" then
    -- object is token, parser error
    if object.type == tt.EOF then
      report(object.line, " at end", message)
    else
      report(object.line, " at '" .. object.lexeme .. "'", message)
    end
  end
end

local function runtimeerror(err)
  io.stderr:write(("%s\n[line %s]"):format(err.message, err.token.line))
  hadruntimeerror = true
end

return {
  haderror = haderror,
  hadruntimeerror = hadruntimeerror,
  error = error,
  runtimeerror = runtimeerror,
}
