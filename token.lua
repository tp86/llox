local tokenmt = {
  __tostring = function(self)
    return ("%s %s %s"):format(self.type, self.lexeme, self.literal)
  end
}
return function(type, lexeme, literal, line)
  return setmetatable({
    type = type,
    lexeme = lexeme,
    literal = literal,
    line = line,
  }, tokenmt)
end
