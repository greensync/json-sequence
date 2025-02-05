require_relative 'result'
require 'multi_json'

module JsonSequence
  class Parser
    RS = "\x1E".freeze

    def initialize
      @buffer = ''
    end

    def parse(chunk, &block)
      @buffer = do_parse(@buffer + chunk, &block)
    end

    private

    # Takes a String buffer to parse and returns String containing any
    # text remaining to parse when more data is available.
    def do_parse(buffer)
      # RFC7464 2.1 Multiple consecutive RS octets do not denote empty
      # sequence elements between them and can be ignored.
      records = buffer.split(RS).reject(&:empty?)

      # Every record except the last is guaranteed to be completed
      records[0...-1].each { |record| yield decode_record(record) }

      last_result = decode_record(records.last)

      # If we have an incomplete record and run out of valid json early, return it to the buffer
      return records.last if !buffer.end_with?(RS) && partial_result?(last_result)
      yield last_result

      ''
    end

    def decode_record(record)
      value = MultiJson.load(record)
      return JsonSequence::Result::MaybeTruncated.new(value) if truncated?(record, value)

      JsonSequence::Result::Json.new(value)
    rescue MultiJson::ParseError => e
      JsonSequence::Result::ParseError.new(record, e)
    end

    def truncated?(record, value)
      case value
      when Numeric, TrueClass, FalseClass, NilClass
        # Check for truncation, if record was parsed but doesn't end in
        # whitespace it may be truncated
        record !~ /\s$/
      else
        false
      end
    end

    def partial_result?(result)
      !result.is_a?(JsonSequence::Result::Json)
    end
  end
end
