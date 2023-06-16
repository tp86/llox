#!/usr/bin/env lua

local errorhandler = require("error")
local scantokens = require("scanner")
local parse = require("parser")
local astprinter = require("astprinter")

local function run(source)
  local tokens = scantokens(source)
  local expression = parse(tokens)
  if errorhandler.haderror then return end
  print(astprinter.print(expression))
end

local function runfile(path)
  local bytes
  do
    local file = assert(io.open(path))
    bytes = file:read("a")
    file:close()
  end
  run(bytes)
  if errorhandler.haderror then os.exit(65) end
end

local function runprompt()
  while true do
    print("> ")
    local line = io.read()
    if not line then break end
    run(line)
    errorhandler.haderror = false
  end
end

local function main()
  if #arg > 1 then
    print(("Usage: %s [script]"):format(arg[0]))
    os.exit(64)
  elseif #arg == 1 then
    runfile(arg[1])
  else
    runprompt()
  end
end

main()
