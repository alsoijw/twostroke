module Twostroke::AST
  class Case < Base
    property :expression, :statements

    def initialize(@line : Int32, @expression : Base? = nil)
      @statements = [] of Base
      @is_default = false
    end

    def walk(&bk)
      if yield self
        expression.walk &bk if expression
        statements.each { |s| s.walk &bk }
      end
    end
  end
end
