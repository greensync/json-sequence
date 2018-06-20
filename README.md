# JsonSequence

A push parser for [RFC7464 JSON Text Sequences](https://tools.ietf.org/html/rfc7464)

## Usage

The parser is intended for use in scenarios where data is being streamed in
chunks, either from the file system or from the network. As each new chuck of
data is received it is pushed to the parser, which will yield the parsed values
contained within.

```ruby
require 'net/http'
require 'json_sequence'

uri = URI('http://example.com/json_sequence')
parser = JsonSequence::Parser.new

Net::HTTP.start(uri.host, uri.port) do |http|
  request = Net::HTTP::Get.new uri

  http.request request do |response|
    response.value # raises if not success

    response.read_body do |chunk|
      parser.parse(chunk) do |result|
        case result
        when JsonSequence::Result::Json
          puts "received record: #{result.value.inspect}"
        when JsonSequence::Result::MaybeTruncated
          puts "received possibly truncated record: #{result.value.inspect}"
        when JsonSequence::Result::ParseError
          puts "stream contained invalid record: #{result.record}, caused by: #{reuslt.error.message}"
        end
      end
    end
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).
