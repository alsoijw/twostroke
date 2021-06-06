module Twostroke::AST
  class Break < Base
    property :label

    def initialize(@line : Int32, @label : ::Array(::String) | Float64 | Int32 | ::String | Nil = nil)
    end

    def walk
      yield self
    end
  end
end
