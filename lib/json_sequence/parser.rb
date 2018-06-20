require 'json_sequence/result'
require 'multi_json'

module JsonSequence
  class Parser
    RS = "\x1E".freeze

    def initialize
      @buffer = ''
    end

    def parse(chunk, &block)
      @buffer << chunk
      do_parse(&block)
    end

    def finish(&block)
      # Parse remnants in buffer
      do_parse(last_parse: true, &block)
    end

    private

    def do_parse(last_parse: false)
      records = @buffer.split(RS)
      records.each_with_index do |record, i|
        # RFC7464 2.1 Multiple consecutive RS octets do not denote empty
        # sequence elements between them and can be ignored.
        next if record == ''

        # Try to decode the record
        begin
          value = MultiJson.load(record)
          result, remaining = handle_parsed(record, value)
        rescue MultiJson::ParseError => err
          result, remaining = handle_err(record, err, last_record: i == records.size - 1, last_parse: last_parse)
        end

        yield result unless result.nil?
        @buffer = remaining
      end
    end

    def handle_parsed(record, value)
      case value
      when Numeric, TrueClass, FalseClass, NilClass
        # Check for truncation, if record was parsed but doens't end in whitespace it may be truncated
        if record !~ /\s$/
          [JsonSequence::Result::MaybeTruncated.new(value), '']
        else
          [JsonSequence::Result::Json.new(value), '']
        end
      else
        [JsonSequence::Result::Json.new(value), '']
      end
    end

    def handle_err(record, err, last_record:,  last_parse:)
      if !last_record || last_parse
        [JsonSequence::Result::ParseError.new(record, err), '']
      else
        # Last record, might be incomplete, stash for later
        [nil, record]
      end
    end
  end
end
