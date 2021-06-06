module Twostroke::AST
  class Declaration < Base
    property :name

    def initialize(@line : Int32, @name : ::Array(::String) | Float64 | Int32 | ::String | Nil = nil)
    end

    def walk
      yield self
    end
  end
end
