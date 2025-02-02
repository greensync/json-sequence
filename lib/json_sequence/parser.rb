require 'json_sequence/result'
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
      records = buffer.split(RS, -1) # -1 stops suppression of trailing null fields

      records.each_with_index do |record, i|
        # RFC7464 2.1 Multiple consecutive RS octets do not denote empty
        # sequence elements between them and can be ignored.
        next if record == ''

        is_last_record = i == records.size - 1

        # Try to decode the record
        begin
          value = MultiJson.load(record)
          if truncated?(record, value)
            return record if is_last_record

            yield JsonSequence::Result::MaybeTruncated.new(value)
          else
            yield JsonSequence::Result::Json.new(value)
          end
        rescue MultiJson::ParseError => err
          return record if is_last_record

          yield JsonSequence::Result::ParseError.new(record, err)
        end
      end

      ''
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
  end
end
