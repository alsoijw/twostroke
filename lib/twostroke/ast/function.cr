module Twostroke::AST
  class Function < Base
    property :name, :arguments, :statements, :fnid, :as_expression

    def initialize(
      @line : Int32,
      @arguments = [] of Float64 | Int32 | ::String | Base | Nil | ::Array(::String),
      @statements = [] of AST::Base,
      @as_expression = false)
    @name = ""
    end

    def walk(&bk)
      if yield self
        statements.each { |s| s.walk &bk }
      end
    end
  end
end
