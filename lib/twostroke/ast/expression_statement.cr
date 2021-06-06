module Twostroke::AST
  class ExpressionStatement < Base
    property :expr

    def initialize(@line : Int32, @expr : Base)
    end

    def walk(&bk)
      if yield self
        expr.walk &bk
      end
    end
  end
end
