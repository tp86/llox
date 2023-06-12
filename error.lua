local haderror = false

local function report(line, where, message)
  io.stderr:write(("[line %s] Error%s: %s\n"):format(line, where, message))
  haderror = true
end

local function error(line, message)
  report(line, "", message)
end

return {
  haderror = haderror,
  error = error,
}
