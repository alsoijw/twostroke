module Twostroke::AST
  class Index < Base
    property :object, :index

    def initialize(@line : Int32, @object : Base? = nil, @index : Base? = nil)
    end

    def walk(&bk)
      if yield self
        object.walk &bk
        index.walk &bk
      end
    end
  end
end
