module Twostroke::AST
  class Named < Base
    property :name

    def initialize(@line : Int32, @name : ::String)
    end

    def walk
      yield self
    end
  end

  class Declaration < Named
  end
end
