module Twostroke::AST
  {% for name, index in [
    "PostIncrement", "PreIncrement", "PostDecrement", "PreDecrement", "Delete",
    "BinaryNot", "UnaryPlus", "Negation", "TypeOf", "Not", "Void", "BracketedExpression"] %}
    class {{ name.id }} < Base
      property :value

      def initialize(@line = 0, @value : ::Array(::String) | Float64 | Int32 | ::String | Nil | Number = nil)
      end

      def initialize(@line = 0, @value : Base? = nil)
      end

      def walk(&bk)
        if yield self
          value.walk &bk
        end
      end
    end
  {% end %}
end
