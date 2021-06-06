module Twostroke::AST
  class Ternary < Base
    property :condition, :if_true, :if_false

    @if_true : Base?
    @if_false : Base?

    def initialize(@line : Int32, @condition : Base?)
    end

    def walk(&bk)
      if yield self
        condition.walk &bk
        if_true.walk &bk
        if_false.walk &bk
      end
    end
  end
end
