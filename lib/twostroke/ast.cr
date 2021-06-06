module Twostroke
  module AST
    class Base
      property :line

      def initialize(@line : Int32)
      end
    end
  end
end

require "./ast/*"
