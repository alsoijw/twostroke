module Twostroke::AST
  class While < Base
    property :condition, :body

    def initialize(@line : Int32, @body : Base? = nil, @condition : Base? = nil)
    end

    def walk(&bk)
      if yield self
        condition.walk &bk
        body.walk &bk if body
      end
    end
  end
end
