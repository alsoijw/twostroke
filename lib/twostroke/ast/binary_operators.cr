module Twostroke::AST

    class BinaryOperator < Base
      property :left, :right, :assign_result_left

      def initialize(@line : Int32, @left : Base? = nil, @right : Base? = nil, @assign_result_left = false)
      end

      def walk(&bk)
        if yield self
          left.walk &bk
          right.walk &bk
        end
      end
    end

    {% for klass in %w(
      Addition Subtraction Multiplication Division Modulus
      LeftShift RightArithmeticShift RightLogicalShift
      LessThan LessThanEqual GreaterThan GreaterThanEqual
      In InstanceOf Equality Inequality StrictEquality
      StrictInequality BitwiseAnd BitwiseXor BitwiseOr
      And Or
    ) %}
      class {{ klass.id }} < BinaryOperator
      end
  {% end %}
end
