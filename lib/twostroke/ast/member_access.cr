module Twostroke::AST
  class MemberAccess < Base
    property :object, :member

    def initialize(@line : Int32, @object : Twostroke::AST::Base?, @member : ::Array(::String) | Float64 | Int32 | ::String | Nil)
    end

    def walk(&bk)
      if yield self
        object.walk &bk
      end
    end
  end
end
