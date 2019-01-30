
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "json_sequence/version"

Gem::Specification.new do |spec|
  spec.name          = "json-sequence"
  spec.version       = JsonSequence::VERSION
  spec.authors       = ["Wesley Moore"]
  spec.email         = ["wes.moore@greensync.com.au"]

  spec.summary       = %q{Push parser for RFC7464 JSON Sequences}
  spec.homepage      = "https://github.com/greensync/json-sequence"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    Dir.glob("{bin,lib}/**/*") + %w[README.md Gemfile Gemfile.lock Rakefile LICENSE.txt json-sequence.gemspec]
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "multi_json", "~> 1.13"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "json", "~> 2.0"
end
