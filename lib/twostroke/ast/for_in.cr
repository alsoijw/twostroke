module Twostroke::AST
  class ForIn < Base
    property :lval, :object, :body

    def initialize(@line : Int32, @lval : Base?, @object : Base?, @body : Base?)
    end

    def walk(&bk)
      if yield self
        lval.walk &bk
        object.walk &bk
        body.walk &bk
      end
    end
  end
end
