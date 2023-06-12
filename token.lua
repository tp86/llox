return function(type, lexeme, literal, line)
  return setmetatable({
    type = type,
    lexeme = lexeme,
    literal = literal,
    line = line,
  }, {
    __tostring = function(self)
      return ("%s %s %s"):format(self.type, self.lexeme, self.literal)
    end
  })
end
