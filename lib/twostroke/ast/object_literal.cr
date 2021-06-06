module Twostroke::AST
  class ObjectLiteral < Base
    property :items

    def initialize(@line : Int32)
      @items = [] of ::Array(Token) | ::Array(Base | Token | Nil)
    end

    def walk(&bk)
      if yield self
        items.each { |i| i[1].walk &bk }
      end
    end
  end
end
