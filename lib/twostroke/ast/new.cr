module Twostroke::AST
  class New < Base
    property :callee, :arguments

    def initialize(@line : Int32, @name = "", @callee : Base? = nil)
      @arguments = [] of Base?
    end

    def walk(&bk)
      if yield self
        callee.walk &bk
        arguments.each { |a| a.walk &bk }
      end
    end
  end
end
