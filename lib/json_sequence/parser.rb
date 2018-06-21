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

        # Try to decode the record
        begin
          value = MultiJson.load(record)
          result, remaining = handle_parsed(record, value, is_last_record: i == records.size - 1)
        rescue MultiJson::ParseError => err
          result, remaining = handle_err(record, err, is_last_record: i == records.size - 1)
        end

        return remaining if result.nil?
        yield result
      end

      ''
    end

    def handle_parsed(record, value, is_last_record:)
      case value
      when Numeric, TrueClass, FalseClass, NilClass
        # Check for truncation, if record was parsed but doesn't end in
        # whitespace it may be truncated
        if record !~ /\s$/
          return is_last_record ? [nil, record] : [JsonSequence::Result::MaybeTruncated.new(value), '']
        end
      end

      [JsonSequence::Result::Json.new(value), '']
    end

    def handle_err(record, err, is_last_record:)
      # Last record, might be incomplete, stash for later
      is_last_record ? [nil, record] : [JsonSequence::Result::ParseError.new(record, err), '']
    end
  end
end
