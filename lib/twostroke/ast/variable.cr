module Twostroke::AST
  class Variable < Base
    property :name

    def initialize(@line : Int32, @name = "")
    end

    def walk
      yield self
    end
  end
end
