# frozen_string_literal: true

require_relative "lib/rspec/trace/version"

Gem::Specification.new do |spec|
  spec.name = "rspec-trace-formatter"
  spec.version = RSpec::Trace::VERSION
  spec.authors = ["Zach Thomae"]
  spec.email = ["zach@thomae.co"]

  spec.summary = "Formatter for RSpec to represent test runs as trace events"
  spec.description = "Create traces from RSpec tests using OpenTelemetry or your own tracing library"
  spec.homepage = "https://github.com/zthomae/rspec-trace-formatter"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.5.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/zthomae/rspec-trace-formatter"

  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }

  spec.add_runtime_dependency "opentelemetry-api", "~> 1.0"
  spec.add_runtime_dependency "opentelemetry-exporter-otlp", "~> 0.20"
  spec.add_runtime_dependency "rspec-core", "~> 3.0"
  spec.add_runtime_dependency "subprocess", "~> 1.0"

  spec.add_development_dependency "activesupport", "~> 6.0"
  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "standard", "~> 1.3.0"
  spec.add_development_dependency "lefthook", "~> 0.7.7"
  spec.add_development_dependency "rake", "~> 13.0.6"
  spec.add_development_dependency "pry", "~> 0.13"
  spec.add_development_dependency "pry-byebug", "~> 3.9.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-snapshot", "~> 2.0"
  spec.add_development_dependency "timecop", "~> 0.9"
end
