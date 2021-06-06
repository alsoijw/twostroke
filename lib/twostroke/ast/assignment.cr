module Twostroke::AST
  class Assignment < Base
    property :left, :right

    def initialize(@left : Base?, @line : Int32, @right : Base?)
    end
 
    def walk(&bk)
      if yield self
        left.walk &bk
        right.walk &bk
      end
    end
  end
end
