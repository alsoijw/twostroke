module Twostroke::AST
  class Body < Base
    property :statements

    def initialize(@line : Int32)
      @statements = [] of Base
    end

    def walk(&bk)
      if yield self
        statements.each { |s| s.walk &bk }
      end
    end
  end
end
