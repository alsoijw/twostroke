module Twostroke::AST
  class Switch < Base
    property :expression, :cases

    def initialize(@line : Int32, @expression : Base?, @cases = [] of Base)
    end

    def walk(&bk)
      if yield self
        expression.walk &bk
        cases.each { |c| c.walk &bk }
      end
    end
  end
end
