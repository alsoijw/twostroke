module Twostroke::AST
  class Label < Base
    property :name, :statement

    def initialize(@line : Int32, @name : ::Array(::String) | Float64 | Int32 | ::String | Nil, @statement : Base?)
    end

    def walk(&bk)
      if yield self
        statement.walk &bk
      end
    end
  end
end
