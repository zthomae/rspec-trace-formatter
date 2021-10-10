# frozen_string_literal: true

require_relative "lib/rspec/trace/version"

Gem::Specification.new do |spec|
  spec.name = "rspec-trace-formatter"
  spec.version = RSpec::Trace::VERSION
  spec.authors = ["Zach Thomae"]
  spec.email = ["zach@thomae.co"]

  spec.summary = "Formatter for RSpec to represent test runs as OpenTelemetry traces"
  spec.description = "Formatter for RSpec to represent test runs as OpenTelemetry traces"
  spec.homepage = "https://github.com/zthomae/rspec-trace-formatter"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/zthomae/rspec-trace-formatter"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir["{lib}/**/*"]

  spec.add_runtime_dependency "opentelemetry-api", "~> 1.0"
  spec.add_runtime_dependency "opentelemetry-exporter-otlp", "~> 0.20"

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "standard", "~> 1.3.0"
  spec.add_development_dependency "lefthook", "~> 0.7.7"
  spec.add_development_dependency "rake", "~> 13.0.6"
  spec.add_development_dependency "pry", "~> 0.13"
  spec.add_development_dependency "pry-byebug", "~> 3.9.0"
end
