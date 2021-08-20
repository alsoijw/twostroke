module Twostroke
  class Lexer
    def self.unescape_string(str)
      str.gsub(/\\(([0-6]{1,3})|u([a-f0-9]{4})|x([a-f0-9]{2})|\n|.)/i) do |m|
        case m
        when /\\([0-6]{1,3})/; m[1..-1].to_i(8).chr
        when /\\u([a-f0-9]{4})/i; m[2..-1].to_i(16).chr
        when /\\x([a-f0-9]{2})/i; m[2..-1].to_i(16).chr
        else case m[1]
        when "b"; "\b"
        when "n"; "\n"
        when "f"; "\f"
        when "v"; "\v"
        when "r"; "\r"
        when "t"; "\t"
        when "\n"; ""
        else; m[1]         end
        end
      end
    end

    RESERVED = %w(
      function var if instanceof in else for while do this return
      throw typeof try catch finally void null new delete switch
      case break continue default true false with debugger)
    {% begin %}
      TOKENS = [

        {:MULTI_COMMENT, %r{/\*.*?\*/}},
        {:SINGLE_COMMENT, /\/\/.*?($|\r|\x{2029}|\x{2028})/},

        {:LINE_TERMINATOR, /[\n\r\x{2028}\x{2029}]/},
        {:WHITESPACE, /[ \t\r\v\f]+/},
        {:NUMBER, /((?<oct>0[0-7]+)|(?<hex>0x[A-Fa-f0-9]+)|(?<to_f>(\d+(\.?\d*([eE][+-]?\d+)?)?|\.\d+([eE][+-]?\d+)?)))/, ->(m : Regex::MatchData) {
          method, number = m.regex.name_table.values.zip(m.captures).select { |k, v| v }.first
          if number.nil?
            0
          else
            case method
            when "oct"
              n = number.to_i(leading_zero_is_octal: true)
            when "hex"
              n = number.to_i 16
            else
              n = number.to_f
            end
            if (n % 1).zero?
              n.to_i
            else
              n
            end
          end
        }},
        {% for w in RESERVED %}
          { :{{ w.id.upcase }}, /{{ w.id }}(?=[^a-zA-Z_0-9])/},
        {% end %}
        {:BAREWORD, /[a-zA-Z_\$][\$a-zA-Z_0-9]*/, ->(m : Regex::MatchData) { m[0] }},
        {:STRING, /(["'])((\\\n|\\.|((?!\1)(?!\\).))*?((?!\1)(?!\\).)?)\1/, ->(m : Regex::MatchData) { unescape_string m[2] }},
        {:REGEXP, %r{/(?<src>(\\.|[^\1])*?[^\1\\]?)/(?<opts>[gim]+)?}, ->(m : Regex::MatchData) {
          str = m[:src.to_s].
            gsub(/\\u([0-9a-f]{4})/i) { |m| m[2..-1].to_i(16).chr }.
            gsub(/\\x([0-9a-f]{2})/i) { |m|
            cp = m[2..-1].to_i 16
            if cp < 127
              "\\x#{cp.to_s 16}"
            else
              cp.chr
            end
          }
          [str, m[:opts.to_s]]
        }},
        {:OPEN_PAREN, /\(/},
        {:CLOSE_PAREN, /\)/},
        {:OPEN_BRACKET, /\[/},
        {:CLOSE_BRACKET, /\]/},
        {:OPEN_BRACE, /\{/},
        {:CLOSE_BRACE, /\}/},
        {:MEMBER_ACCESS, /\./},
        {:ADD_EQUALS, /\+=/},
        {:MINUS_EQUALS, /-=/},
        {:TIMES_EQUALS, /\*=/}, # textmate barfs it's syntax highlighting on this one lol
        {:DIVIDE_EQUALS, /\/=/},
        {:MOD_EQUALS, /%=/},
        {:LEFT_SHIFT_EQUALS, /<<=/},
        {:RIGHT_TRIPLE_SHIFT_EQUALS, />>>=/},
        {:RIGHT_SHIFT_EQUALS, />>=/},
        {:BITWISE_AND_EQUALS, /&=/},
        {:BITWISE_XOR_EQUALS, /\^=/},
        {:BITWISE_OR_EQUALS, /\|=/},
        {:INCREMENT, /\+\+/},
        {:DECREMENT, /--/},
        {:PLUS, /\+/},
        {:MINUS, /-/},
        {:ASTERISK, /\*/},
        {:SLASH, /\//},
        {:MOD, /%/},
        {:QUESTION, /\?/},
        {:COMMA, /,/},
        {:SEMICOLON, /;/},
        {:COLON, /:/},
        {:AND, /&&/},
        {:AMPERSAND, /&/},
        {:OR, /\|\|/},
        {:PIPE, /\|/},
        {:TRIPLE_EQUALS, /===/},
        {:DOUBLE_EQUALS, /==/},
        {:EQUALS, /=/},
        {:NOT_DOUBLE_EQUALS, /!==/},
        {:NOT_EQUALS, /!=/},
        {:NOT, /!/},
        {:TILDE, /~/},
        {:CARET, /\^/},
        {:LEFT_SHIFT, /<</},
        {:RIGHT_TRIPLE_SHIFT, />>>/},
        {:RIGHT_SHIFT, />>/},
        {:LTE, /<=/},
        {:GTE, />=/},
        {:LT, /</},
        {:GT, />/},

      ].map do |a|
        if a.is_a? Tuple(Symbol, Regex) 
          {a[0], /\G#{a[1].source}/m, nil }
        else
          {a[0], /\G#{a[1].source}/m, a[2] }
        end
      end
    {% end %}
  end
end
