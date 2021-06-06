module Twostroke::AST
  class With < Base
    property :object, :statement

    def initialize(@line : Int32, @object : Base?, @statement : Base? = nil)
    end

    def walk(&bk)
      if yield self
        object.walk &bk
        statement.walk &bk
      end
    end
  end
end
