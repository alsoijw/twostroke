module Twostroke
  class ParseError < SyntaxError
  end

  class Parser
    getter :statements

    @peek_token : Twostroke::Token | Nil

    def initialize(lexer : Twostroke::Lexer)
      @i = -1
      @lexer = lexer
      @statements = [] of Twostroke::AST::Base
    end

    def parse
      while try_peek_token(true)
        st = statement
        statements.push st if st
      end
    end

    private def error!(msg)
      raise ParseError.new "Syntax error at line #{token.line}, col #{token.col}. #{msg}"
    end

    private def assert_type(tok, *types)
      error! "Found #{tok.type}#{"<#{tok.val}>" if tok.val}, expected #{types.join ", "}" unless types.includes? tok.type
    end

    private def save_state
      { cur_token: @cur_token, peek_token: @peek_token, lexer_state: @lexer.state }
    end

    private def load_state(state)
      @cur_token = state[:cur_token]
      @peek_token = state[:peek_token]
      @lexer.state = state[:lexer_state]
    end

    private def token
      @cur_token || raise ParseError.new "unexpected end of input"
    end

    private def next_token(allow_regexp = false)
      @cur_token = @peek_token || @lexer.read_token(allow_regexp)
      @peek_token = nil
      token
    end

    private def try_peek_token(allow_regexp = false)
      @peek_token ||= @lexer.read_token(allow_regexp)
    end

    private def peek_token(allow_regexp = false)
      @peek_token ||= @lexer.read_token(allow_regexp) || raise ParseError.new "unexpected end of input"
    end

    ####################

    private def statement(consume_semicolon = true)
      st = case peek_token.type
           when :RETURN; self.return
           when :BREAK; self.break
           when :CONTINUE; continue
           when :THROW; self.throw
           when :DEBUGGER; debugger
           when :VAR; var
           when :WITH; consume_semicolon = false; self.with
           when :IF; consume_semicolon = false; self.if
           when :FOR; consume_semicolon = false; self.for
           when :SWITCH; consume_semicolon = false; self.switch
           when :DO; self.do
           when :WHILE; consume_semicolon = false; self.while
           when :TRY; consume_semicolon = false; try
           when :OPEN_BRACE; consume_semicolon = false; body
           when :FUNCTION; consume_semicolon = false; function(false)
           when :SEMICOLON; nil
           when :LINE_TERMINATOR; nil
           when :BAREWORD; label
      else; expression_statement
      end
      if consume_semicolon
        if try_peek_token && peek_token.type == :SEMICOLON
          next_token
        end
      end
      st
    end

    private def label
      state = save_state
      assert_type next_token, :BAREWORD
      name = token.val
      if try_peek_token && peek_token.type == :COLON
        next_token
        return AST::Label.new name: name, line: token.line, statement: statement(false)
      else
        load_state state
        expression_statement
      end
    end

    private def expression_statement
      expr = expression
      if !expr.nil?
        AST::ExpressionStatement.new expr: expr, line: expr.line
      else
        exit # FIXME
      end   
    end

    private def expression
      multi_expression
    end

    private def multi_expression
      expr = assignment_expression
      while try_peek_token && peek_token.type == :COMMA
        next_token
        expr = AST::MultiExpression.new left: expr, line: token.line, right: assignment_expression
      end
      expr
    end

    private def assignment_expression
      nodes = {
        :ADD_EQUALS => AST::Addition,
        :MINUS_EQUALS => AST::Subtraction,
        :TIMES_EQUALS => AST::Multiplication,
        :DIVIDE_EQUALS => AST::Division,
        :MOD_EQUALS => AST::Modulus,
        :LEFT_SHIFT => AST::LeftShift,
        :RIGHT_SHIFT_EQUALS => AST::RightLogicalShift,
        :RIGHT_TRIPLE_SHIFT_EQUALS => AST::RightArithmeticShift,
        :BITWISE_AND_EQUALS => AST::BitwiseAnd,
        :BITWISE_XOR_EQUALS => AST::BitwiseXor,
        :BITWISE_OR_EQUALS => AST::BitwiseOr,
      }
      expr = conditional_expression
      if try_peek_token && peek_token.type == :EQUALS
        next_token
        expr = AST::Assignment.new left: expr, line: token.line, right: assignment_expression
      elsif try_peek_token && nodes.keys.includes? peek_token.type
        expr = nodes[next_token.type].new left: expr, line: token.line, assign_result_left: true, right: assignment_expression
      end
      expr
    end

    private def conditional_expression
      cond = logical_or_expression
      if try_peek_token && peek_token.type == :QUESTION
        next_token
        cond = AST::Ternary.new line: token.line, condition: cond
        cond.if_true = assignment_expression
        assert_type next_token, :COLON
        cond.if_false = assignment_expression
      end
      cond
    end

    private def logical_or_expression
      expr = logical_and_expression
      while try_peek_token && peek_token.type == :OR
        next_token
        expr = AST::Or.new left: expr, line: token.line, right: logical_and_expression
      end
      expr
    end

    private def logical_and_expression
      expr = bitwise_or_expression
      while try_peek_token && peek_token.type == :AND
        next_token
        expr = AST::And.new left: expr, line: token.line, right: bitwise_or_expression
      end
      expr
    end

    private def bitwise_or_expression
      expr = bitwise_xor_expression
      while try_peek_token && peek_token.type == :PIPE
        next_token
        expr = AST::BitwiseOr.new left: expr, line: token.line, right: bitwise_xor_expression
      end
      expr
    end

    private def bitwise_xor_expression
      expr = bitwise_and_expression
      while try_peek_token && peek_token.type == :CARET
        next_token
        expr = AST::BitwiseXor.new left: expr, line: token.line, right: bitwise_and_expression
      end
      expr
    end

    private def bitwise_and_expression
      expr = equality_expression
      while try_peek_token && peek_token.type == :AMPERSAND
        next_token
        expr = AST::BitwiseAnd.new left: expr, line: token.line, right: equality_expression
      end
      expr
    end

    private def equality_expression
      nodes = {
        :DOUBLE_EQUALS => AST::Equality,
        :NOT_EQUALS => AST::Inequality,
        :TRIPLE_EQUALS => AST::StrictEquality,
        :NOT_DOUBLE_EQUALS => AST::StrictInequality,
      }
      expr = relational_in_instanceof_expression
      while try_peek_token && nodes.keys.includes? peek_token.type
        expr = nodes[next_token.type].new left: expr, line: token.line, right: relational_in_instanceof_expression
      end
      expr
    end

    private def relational_in_instanceof_expression
      nodes = {
        :LT => AST::LessThan,
        :LTE => AST::LessThanEqual,
        :GT => AST::GreaterThan,
        :GTE => AST::GreaterThanEqual,
        :IN => AST::In,
        :INSTANCEOF => AST::InstanceOf,
      }
      expr = shift_expression
      while try_peek_token(true) && nodes.keys.includes? peek_token(true).type
        expr = nodes[next_token(true).type].new left: expr, line: token.line, right: shift_expression
      end
      expr
    end

    private def shift_expression
      nodes = {
        :LEFT_SHIFT => AST::LeftShift,
        :RIGHT_TRIPLE_SHIFT => AST::RightArithmeticShift,
        :RIGHT_SHIFT => AST::RightLogicalShift,
      }
      expr = additive_expression
      while try_peek_token && nodes.keys.includes? peek_token.type
        expr = nodes[next_token.type].new left: expr, line: token.line, right: additive_expression
      end
      expr
    end

    private def additive_expression
      nodes = {
        :PLUS => AST::Addition,
        :MINUS => AST::Subtraction,
      }
      expr = multiplicative_expression
      while try_peek_token && nodes.keys.includes? peek_token.type
        expr = nodes[next_token.type].new left: expr, line: token.line, right: multiplicative_expression
      end
      expr
    end

    private def multiplicative_expression
      nodes = {
        :ASTERISK => AST::Multiplication,
        :SLASH => AST::Division,
        :MOD => AST::Modulus,
      }
      expr = unary_expression
      while try_peek_token && nodes.keys.includes? peek_token.type
        expr = nodes[next_token.type].new left: expr, line: token.line, right: unary_expression
      end
      expr
    end

    private def unary_expression
      case peek_token(true).type
      when :NOT; next_token; AST::Not.new line: token.line, value: unary_expression
      when :TILDE; next_token; AST::BinaryNot.new line: token.line, value: unary_expression
      when :PLUS; next_token; AST::UnaryPlus.new line: token.line, value: unary_expression
      when :MINUS; next_token; AST::Negation.new line: token.line, value: unary_expression
      when :TYPEOF; next_token; AST::TypeOf.new line: token.line, value: unary_expression
      when :VOID; next_token; AST::Void.new line: token.line, value: unary_expression
      when :DELETE; next_token; AST::Delete.new line: token.line, value: unary_expression
      else
        increment_expression
      end
    end

    private def increment_expression
      if peek_token(true).type == :INCREMENT
        next_token(true)
        return AST::PreIncrement.new line: token.line, value: increment_expression
      end
      if peek_token(true).type == :DECREMENT
        next_token(true)
        return AST::PreDecrement.new line: token.line, value: increment_expression
      end

      expr = call_expression

      if try_peek_token && peek_token.type == :INCREMENT
        next_token
        return AST::PostIncrement.new line: token.line, value: expr
      end
      if try_peek_token && peek_token.type == :DECREMENT
        next_token
        return AST::PostDecrement.new line: token.line, value: expr
      end

      expr
    end

    private def call_expression
      expr = value_expression
      while try_peek_token && [:MEMBER_ACCESS, :OPEN_BRACKET, :OPEN_PAREN].includes? peek_token.type
        if peek_token.type == :MEMBER_ACCESS
          expr = member_access expr
        elsif peek_token.type == :OPEN_BRACKET
          expr = index expr
        elsif peek_token.type == :OPEN_PAREN
          expr = call expr
        end
      end
      expr
    end

    private def value_expression
      case peek_token(true).type
      when :FUNCTION; function(true)
      when :STRING; string
      when :NUMBER; number
      when :REGEXP; regexp
      when :THIS; this
      when :NULL; null
      when :TRUE; self.true
      when :FALSE; self.false
      when :NEW; new
      when :BAREWORD; bareword
      when :OPEN_BRACKET; array
      when :OPEN_BRACE; object_literal
      when :OPEN_PAREN; parens
      else error! "Unexpected #{peek_token.type}"
      end
    end

    private def new
      assert_type next_token, :NEW
      node = AST::New.new line: token.line
      node.callee = new_call_expression
      if try_peek_token && peek_token.type == :OPEN_PAREN
        call = call node.callee
        node.arguments = call.arguments
      end
      node
    end

    private def new_call_expression
      expr = value_expression
      while try_peek_token && [:MEMBER_ACCESS, :OPEN_BRACKET].includes? peek_token.type
        if peek_token.type == :MEMBER_ACCESS
          expr = member_access expr
        elsif peek_token.type == :OPEN_BRACKET
          expr = index expr
        end
      end
      expr
    end

    private def body
      assert_type next_token, :OPEN_BRACE
      body = AST::Body.new line: token.line
      while peek_token.type != :CLOSE_BRACE
        stmt = statement
        body.statements.push stmt if stmt
      end
      assert_type next_token, :CLOSE_BRACE
      body
    end

    private def this
      assert_type next_token, :THIS
      AST::This.new line: token.line
    end

    private def null
      assert_type next_token, :NULL
      AST::Null.new line: token.line
    end

    private def true
      assert_type next_token, :TRUE
      AST::True.new line: token.line
    end

    private def false
      assert_type next_token, :FALSE
      AST::False.new line: token.line
    end

    private def bareword
      assert_type next_token, :BAREWORD
      AST::Variable.new line: token.line, name: token.val.to_s
    end

    private def with
      assert_type next_token, :WITH
      assert_type next_token, :OPEN_PAREN
      with_ = AST::With.new line: token.line, object: expression
      assert_type next_token, :CLOSE_PAREN
      with_.statement = statement
      with_
    end

    private def if
      assert_type next_token, :IF
      assert_type next_token, :OPEN_PAREN
      node = AST::If.new line: token.line, condition: expression
      assert_type next_token, :CLOSE_PAREN
      node.then = statement
      if try_peek_token && peek_token.type == :ELSE
        assert_type next_token, :ELSE
        node.else = statement
      end
      node
    end

    private def for
      assert_type next_token, :FOR
      assert_type next_token, :OPEN_PAREN
      # decide if this is a for(... in ...) or a for(;;) loop
      saved_state = save_state
      if next_token.type == :VAR && next_token.type == :BAREWORD && next_token.type == :IN
        for_in = true
        load_state saved_state
      else
        load_state saved_state
        stmt = statement(false) unless peek_token.type == :SEMICOLON
        assert_type next_token, :SEMICOLON, :CLOSE_PAREN
        for_in = (token.type == :CLOSE_PAREN)
      end
      load_state saved_state
      if for_in
        # no luck parsing for(;;), reparse as for(..in..)
        if peek_token.type == :VAR
          next_token
          assert_type next_token, :BAREWORD
          lval = AST::Declaration.new line: token.line, name: token.val
        else
          lval = shift_expression # shift_expression is the precedence level right below in's
        end
        assert_type next_token, :IN
        obj = expression
        assert_type next_token, :CLOSE_PAREN
        AST::ForIn.new line: token.line, lval: lval, object: obj, body: statement
      else
        initializer = statement(false) unless peek_token.type == :SEMICOLON
        initializer = initializer.expr if initializer.is_a? AST::ExpressionStatement
        assert_type next_token, :SEMICOLON
        condition = statement(false) unless peek_token.type == :SEMICOLON
        condition = condition.expr if condition.is_a? AST::ExpressionStatement
        assert_type next_token, :SEMICOLON
        increment = statement(false) unless peek_token.type == :CLOSE_PAREN
        increment = increment.expr if increment.is_a? AST::ExpressionStatement
        assert_type next_token, :CLOSE_PAREN
        AST::ForLoop.new line: token.line, initializer: initializer, condition: condition, increment: increment, body: statement
      end
    end

    private def switch
      assert_type next_token, :SWITCH
      assert_type next_token, :OPEN_PAREN
      sw = AST::Switch.new line: token.line, expression: expression
      assert_type next_token, :CLOSE_PAREN
      assert_type next_token, :OPEN_BRACE
      current_case = nil
      default = false
      while ![:CLOSE_BRACE].includes? peek_token.type
        if peek_token.type == :CASE
          assert_type next_token, :CASE
          expr = expression
          node = AST::Case.new line: token.line, expression: expr
          assert_type next_token, :COLON
          sw.cases << node if node
          current_case = node.statements
        elsif peek_token.type == :DEFAULT
          assert_type next_token, :DEFAULT
          error! "only one default case allowed" if default
          default = true
          node = AST::Case.new line: token.line
          assert_type next_token, :COLON
          sw.cases << node if node
          current_case = node.statements
        else
          error! "statements may only appear under a case" if current_case.nil?
          stmt = statement
          current_case << stmt if stmt
        end
      end
      assert_type next_token, :CLOSE_BRACE
      sw
    end

    private def while
      assert_type next_token, :WHILE
      assert_type next_token, :OPEN_PAREN
      node = AST::While.new line: token.line, condition: expression
      assert_type next_token, :CLOSE_PAREN
      node.body = statement
      node
    end

    private def do
      assert_type next_token, :DO
      node = AST::DoWhile.new line: token.line, body: body
      assert_type next_token, :WHILE
      assert_type next_token, :OPEN_PAREN
      node.condition = expression
      assert_type next_token, :CLOSE_PAREN
      node
    end

    private def try
      assert_type next_token, :TRY
      try = AST::Try.new line: token.line, try_statements: [] of AST::Base?
      assert_type next_token, :OPEN_BRACE
      while peek_token.type != :CLOSE_BRACE
        stmt = statement
        try.try_statements << stmt if stmt
      end
      assert_type next_token, :CLOSE_BRACE
      assert_type next_token, :CATCH, :FINALLY
      if token.type == :CATCH
        try.catch_statements = [] of AST::Base?
        assert_type next_token, :OPEN_PAREN
        assert_type next_token, :BAREWORD
        try.catch_variable = token.val
        assert_type next_token, :CLOSE_PAREN
        assert_type next_token, :OPEN_BRACE
        while peek_token.type != :CLOSE_BRACE
          stmt = statement
          try.catch_statements << stmt if stmt
        end
        assert_type next_token, :CLOSE_BRACE
        next_token if try_peek_token(true) && peek_token(true).type == :FINALLY
      end
      if token && token.type == :FINALLY
        try.finally_statements = [] of AST::Base?
        assert_type next_token, :OPEN_BRACE
        while peek_token.type != :CLOSE_BRACE
          stmt = statement
          try.finally_statements << stmt if stmt
        end
        assert_type next_token, :CLOSE_BRACE
      end
      try
    end

    private def member_access(obj)
      assert_type next_token, :MEMBER_ACCESS
      assert_type next_token, :BAREWORD
      AST::MemberAccess.new line: token.line, object: obj, member: token.val
    end

    private def call(callee)
      assert_type next_token, :OPEN_PAREN
      c = AST::Call.new line: token.line, callee: callee
      while peek_token(true).type != :CLOSE_PAREN
        while true
          c.arguments.push assignment_expression # one level below multi_expression which can separate by comma
          if peek_token.type == :COMMA
            next_token
          else
            break
          end
        end
      end
      next_token
      c
    end

    private def index(obj)
      assert_type next_token, :OPEN_BRACKET
      ind = expression
      assert_type next_token, :CLOSE_BRACKET
      AST::Index.new line: token.line, object: obj, index: ind
    end

    private def debugger
      AST::Debugger.new line: next_token.line
    end

    private def return
      tok = @lexer.restrict do
        assert_type next_token, :RETURN
        peek_token true
      end
      if tok.type == :LINE_TERMINATOR
        next_token true
        return AST::Return.new(line: token.line)
      end
      expr = expression unless peek_token.type == :SEMICOLON || peek_token.type == :CLOSE_BRACE
      AST::Return.new(line: token.line, expression: expr)
    end

    private def break
      tok = @lexer.restrict do
        assert_type next_token, :BREAK
        peek_token
      end
      if tok.type == :LINE_TERMINATOR
        next_token
        return AST::Break.new line: token.line
      end
      label = next_token.val if try_peek_token && peek_token.type == :BAREWORD
      AST::Break.new line: token.line, label: label
    end

    private def continue
      tok = @lexer.restrict do
        assert_type next_token, :CONTINUE
        peek_token
      end
      if tok.type == :LINE_TERMINATOR
        next_token
        return AST::Continue.new line: token.line
      end
      label = next_token.val if try_peek_token && peek_token.type == :BAREWORD
      AST::Continue.new line: token.line, label: label
    end

    private def throw
      tok = @lexer.restrict do
        assert_type next_token, :THROW
        error! "illegal newline after throw" if peek_token(true).type == :LINE_TERMINATOR
      end
      AST::Throw.new line: token.line, expression: expression
    end

    private def delete
      assert_type next_token, :DELETE
      AST::Delete.new line: token.line, expression: expression
    end

    private def var
      assert_type next_token, :VAR
      var_rest
    end

    private def var_rest
      assert_type next_token, :BAREWORD
      decl = AST::Declaration.new line: token.line, name: token.val
      return decl if peek_token.type == :SEMICOLON || peek_token.type == :CLOSE_BRACE

      assert_type next_token, :COMMA, :EQUALS

      if token.type == :COMMA
        AST::MultiExpression.new line: token.line, left: decl, right: var_rest
      else
        assignment = AST::Assignment.new line: token.line, left: decl, right: assignment_expression
        if peek_token.type == :SEMICOLON || peek_token.type == :CLOSE_BRACE
          assignment
        elsif peek_token.type == :COMMA
          next_token
          AST::MultiExpression.new line: token.line, left: assignment, right: var_rest
        else
          error! "Unexpected #{peek_token.type}"
        end
      end
    end

    private def number
      assert_type next_token, :NUMBER
      v = token.val
      if v.is_a? (Float64 | Int32)
        AST::Number.new line: token.line, number: v
      end
    end

    private def string
      assert_type next_token, :STRING
      AST::String.new line: token.line, string: token.val.to_s
    end

    private def regexp
      assert_type next_token, :REGEXP
      AST::Regexp.new line: token.line, regexp: token.val.to_s
    end

    private def object_literal
      assert_type next_token, :OPEN_BRACE
      obj = AST::ObjectLiteral.new line: token.line
      while peek_token.type != :CLOSE_BRACE
        assert_type next_token, :BAREWORD, :STRING, :NUMBER
        key = token
        assert_type next_token, :COLON
        obj.items.push [key, assignment_expression]
        assert_type peek_token, :COMMA, :CLOSE_BRACE
        if peek_token.type == :COMMA
          next_token
          next
        end
      end
      next_token
      obj
    end

    private def array
      assert_type next_token, :OPEN_BRACKET
      ary = AST::Array.new line: token.line
      while peek_token(true).type != :CLOSE_BRACKET
        unless empty_flag = peek_token(true).type == :COMMA
          ary.items.push assignment_expression
        end
        assert_type peek_token, :COMMA, :CLOSE_BRACKET
        if peek_token.type == :COMMA
          next_token
          # ** hack: **
          if empty_flag && peek_token(true).type != :CLOSE_BRACKET
            ary.items.push AST::Void.new value: AST::Number.new(number: 0) # <-- hack
          end
          next
        end
      end
      next_token
      ary
    end

    private def parens
      assert_type next_token, :OPEN_PAREN
      expr = expression
      assert_type next_token, :CLOSE_PAREN
      expr
    end

    private def function(as_expr)
      assert_type next_token, :FUNCTION
      fn = AST::Function.new(
        line: token.line,
        arguments: [] of (Float64 | Int32 | String | AST::Base | Nil | ::Array(::String)),
        statements: [] of AST::Base,
        as_expression: as_expr)
      error! "" unless [:BAREWORD, :OPEN_PAREN].includes? next_token.type
      if token.type == :BAREWORD
        fn.name = token.val.to_s
        assert_type next_token, :OPEN_PAREN
      end
      while peek_token.type == :BAREWORD
        fn.arguments.push next_token.val
        next_token if peek_token.type == :COMMA
      end
      assert_type next_token, :CLOSE_PAREN
      assert_type next_token, :OPEN_BRACE
      while peek_token.type != :CLOSE_BRACE
        stmt = statement
        fn.statements << stmt if stmt
      end
      assert_type next_token, :CLOSE_BRACE
      fn
    end
  end
end
