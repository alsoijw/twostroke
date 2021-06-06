module Twostroke::AST
  class Try < Base
    property :try_statements, :catch_variable, :catch_statements, :finally_statements

    def initialize(@line : Int32, @try_statements : ::Array(Base?), @catch_statements = [] of Base?, @catch_variable : ::Array(::String) | Float64 | Int32 | ::String | Nil = nil, @finally_statements = [] of Base?)
    end

    def walk(&bk)
      if yield self
        try_statements.each { |s| s.walk &bk }
        catch_statements.each { |s| s.walk &bk } if catch_statements
        finally_statements.each { |s| s.walk &bk } if finally_statements
      end
    end
  end
end
