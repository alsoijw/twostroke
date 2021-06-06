module Twostroke::AST
  class MultiExpression < Base
    property :left, :right

    def initialize(@line : Int32, @left : Base? = nil, @right : Base? = nil)
    end

    def walk(&bk)
      if yield self
        left.walk &bk
        right.walk &bk
      end
    end
  end
end
