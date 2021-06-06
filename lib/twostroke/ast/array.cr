module Twostroke::AST
  class Array < Base
    property :items

    def initialize(@line : Int32)
      @items = [] of Twostroke::AST::Base?
    end

    def walk(&bk)
      if yield self
        items.each do |item|
          item.walk &bk
        end
      end
    end
  end
end
