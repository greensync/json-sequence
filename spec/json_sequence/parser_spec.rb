RSpec.describe JsonSequence::Parser do
  let(:parser) { described_class.new }

  # RFC7464 2.1 Multiple consecutive RS octets do not denote empty
  # sequence elements between them and can be ignored.
  it 'ignores multiple consecutive RS octets' do
    expect { |b| parser.parse(%|\x1E{"some": "json"}\x0A\x1E\x1E|, &b) }.to yield_successive_args(
      JsonSequence::Result::Json.new('some' => 'json')
    )
  end

  it 'parses starting with a json seperator correctly' do
    expect { |b| parser.parse(%|\n\x1E|, &b)}.not_to yield_control
  end

  it 'ignores keep alive token RS octet' do
    expect { |b| parser.parse(%|\x1E|, &b) }.not_to yield_control
  end

  it 'supports incremental parsing' do
    expect { |b| parser.parse(%|\x1E{"some": "json"|, &b) }.not_to yield_control
    expect { |b| parser.parse(%|}\x0A|, &b) }.to yield_successive_args(
      JsonSequence::Result::Json.new('some' => 'json')
    )
  end

  it 'parses arrays' do
    expect { |b| parser.parse(%|\x1E[1,2,3]\x0A|, &b) }.to yield_successive_args(
      JsonSequence::Result::Json.new([1,2,3])
    )
  end

  it 'parses multiple records at once' do
    expect { |b| parser.parse(%|\x1E{"some": "json"|, &b) }.not_to yield_control
    expect { |b| parser.parse(%|}\x0A\x1E{"more": "json"}\x0A|, &b) }.to yield_successive_args(
      JsonSequence::Result::Json.new('some' => 'json'),
      JsonSequence::Result::Json.new('more' => 'json')
    )
  end

  it 'yields invalid records and continues parsing' do
    expect { |b| parser.parse(%|\x1E{"some": "json"|, &b) }.not_to yield_control
    expect { |b| parser.parse(%|\x0A\x1E{"more": "json"}\x0A|, &b) }.to yield_successive_args(
      JsonSequence::Result::ParseError,
      JsonSequence::Result::Json.new('more' => 'json')
    )
  end

  # Per RFC8259 JSON can have any valid JSON value at the top-level, not just
  # Objects and Arrays https://tools.ietf.org/html/rfc8259#section-2
  # NOTE: The JSON parser in MRI Ruby only supports Objects and Arrays.
  it 'parses top level values' do
    expect { |b| parser.parse(%|\x1E"string"\x0A\x1Etrue\x0A\x1Efalse\x0A\x1Enull\x0A\x1E1.0\x0A\x1E2\x0A|, &b) }.to yield_successive_args(
      JsonSequence::Result::Json.new('string'),
      JsonSequence::Result::Json.new(true),
      JsonSequence::Result::Json.new(false),
      JsonSequence::Result::Json.new(nil),
      JsonSequence::Result::Json.new(1.0),
      JsonSequence::Result::Json.new(2),
    )
  end

  it 'reports possibly trunctated values' do
    expect { |b| parser.parse(%|\x1E123|, &b) }.not_to yield_control
    expect { |b| parser.parse(%|\x1E|, &b) }.to yield_successive_args(
      JsonSequence::Result::MaybeTruncated.new(123),
    )
  end

  it "doesn't report trunctated values when value is split across chunks" do
    expect { |b| parser.parse(%|\x1E123|, &b) }.not_to yield_control
    expect { |b| parser.parse(%|456\x0A|, &b) }.to yield_successive_args(
      JsonSequence::Result::Json.new(123456),
    )
  end

  it 'process records when ending with a RS token' do
    expect { |b| parser.parse(%|\x1E123\x0A\x1E|, &b) }.to yield_successive_args(
      JsonSequence::Result::Json.new(123),
    )
    expect { |b| parser.parse(%|123\x0A|, &b) }.to yield_successive_args(
      JsonSequence::Result::Json.new(123),
    )
  end

  it 'parses formatted json' do
    expect { |b| parser.parse(%|\x1E{"some": "json",\n"more": 1,\n"even more": []}\x0A|, &b) }.to yield_successive_args(
      JsonSequence::Result::Json.new('some' => 'json', 'more' => 1, 'even more' => [])
    )
  end

  it 'handles many small chunks' do
    expect { |b| parser.parse(%|\x1E{"|, &b) }.not_to yield_control
    expect { |b| parser.parse(%|some|, &b) }.not_to yield_control
    expect { |b| parser.parse(%|": "|, &b) }.not_to yield_control
    expect { |b| parser.parse(%|js|, &b) }.not_to yield_control
    expect { |b| parser.parse(%|on"}\x0A|, &b) }.to yield_successive_args(
      JsonSequence::Result::Json.new('some' => 'json')
    )
  end
end
