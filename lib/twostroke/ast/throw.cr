module Twostroke::AST
  class Throw < Base
    property :expression

    def initialize(@line : Int32, @expression : Base?)
    end

    def walk(&bk)
      if yield self
        expression.walk &bk
      end
    end
  end
end
