local tt = require("tokentype")

local haderror = false

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

return {
  haderror = haderror,
  error = error,
}
