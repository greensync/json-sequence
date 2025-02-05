module JsonSequence
  module Result
    class Json
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def ==(other)
        return false unless other.is_a?(self.class)
        other.value == value
      end

      alias eql? ==
    end

    class ParseError
      attr_reader :record, :error

      def initialize(record, error)
        @record = record
        @error = error
      end
    end

    class MaybeTruncated
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def ==(other)
        return false unless other.is_a?(self.class)
        other.value == value
      end

      alias eql? ==
    end
  end
end
