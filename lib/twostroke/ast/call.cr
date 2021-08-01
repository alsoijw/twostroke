module Twostroke::AST
  class Call < Base
    property :callee, :arguments

    def initialize(@line : Int32, @callee : Named, @arguments = [] of Base?)
    end

    def walk(&bk)
      if yield self
        callee.walk &bk
        arguments.each { |arg| arg.walk &bk }
      end
    end
  end
end
