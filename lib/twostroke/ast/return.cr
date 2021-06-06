module Twostroke::AST
  class Return < Base
    property :expression

    def initialize(@line : Int32, @expression : Base? = nil)
    end

    def walk(&bk)
      if yield self
        expression.walk &bk if expression
      end
    end
  end
end
