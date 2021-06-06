module Twostroke::AST
  class If < Base
    property :condition, :then, :else

	 def initialize(@line : Int32, @condition : Base?, @then : Base? = nil, @else : Base? = nil)
    end

    def walk(&bk)
      if yield self
        condition.walk &bk
        @then.walk &bk
        @else.walk &bk if @else
      end
    end
  end
end
