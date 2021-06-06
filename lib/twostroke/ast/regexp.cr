module Twostroke::AST
  class Regexp < Base
    property :regexp

    def initialize(@line : Int32, @regexp : ::String)
    end

    def walk(&bk)
      yield self
    end
  end
end
