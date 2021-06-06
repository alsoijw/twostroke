module Twostroke::AST
  class ForLoop < Base
    property :initializer, :condition, :increment, :body

    def initialize(@line : Int32, @initializer : Base?, @condition : Base?, @increment : Base?, @body : Base?)
    end

    def walk(&bk)
      if yield self
        initializer.walk(&bk) if initializer
        condition.walk(&bk) if condition
        increment.walk(&bk) if increment
        body.walk &bk if body
      end
    end
  end
end
