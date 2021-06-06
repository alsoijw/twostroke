module Twostroke::AST
  class String < Base
    property :string

    def initialize(@line : Int32, @string : ::String)
    end

    def walk
      yield self
    end
  end
end
