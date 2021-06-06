module Twostroke::AST
  class Number < Base
    property :number

    def initialize(@line = 0, @number : Float64 | Int32 = 0)
    end

    def walk
      yield self
    end
  end
end
