module Twostroke::AST
  class DoWhile < Base
    property :body, :condition

    def initialize(@line : Int32, @body : Body?, @condition : Base? = nil)
    end

    def walk(&bk)
      if yield self
        condition.walk &bk
        body.walk &bk
      end
    end
  end
end
