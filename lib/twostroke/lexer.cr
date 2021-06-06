module Twostroke
  class LexError < SyntaxError
  end

  class Token
    property :type, :val, :line, :col

    def initialize(type : Symbol, val : (Array(String) | Float64 | Int32 | String | Nil), line : Int32, col : Int32)
      @type = type
      @val = val
      @line = line
      @col = col
    end
  end

  class Lexer
    property :str, :offset, :col, :line, :restricted

    def state
      { str: str, col: col, line: line, offset: offset, restricted: restricted }
    end

    def state=(state)
      @str = state[:str]
      @offset = state[:offset]
      @col = state[:col]
      @line = state[:line]
      @restricted = state[:restricted]
    end

    def initialize(str : String)
      @str = str
      @offset = 0
      @col = 1
      @line = 1
      @line_terminator = false
      @restricted = false
    end

    def restrict
      @restricted = true
      retn = yield
      @restricted = false
      retn
    end

    def read_token(allow_regexp = true)
      TOKENS.select { |t| allow_regexp || t[0] != :REGEXP }.each do |token|
        m = token[1].match @str, @offset
        if m
          tok2 = token[2]
          tok = Token.new(token[0], !tok2.nil? ? tok2.call(m) : nil, @line, @col)
          @offset += m[0].size
          newlines = m[0].count "\n"
          @col = 1 if !newlines.zero?
          @line += newlines
          @col += m[0].size - (m[0].rindex("\n") || 0)
          if [:WHITESPACE, :MULTI_COMMENT, :SINGLE_COMMENT].includes?(token[0]) || (!restricted && token[0] == :LINE_TERMINATOR)
            return read_token(allow_regexp)
          else
            return tok
          end
        end
      end
      if @offset < @str.size
        raise LexError.new "Illegal character '#{@str[0]}' at line #{@line}, col #{@col}."
      else
        nil
      end
    end
  end
end
