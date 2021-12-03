# frozen_string_literal: true

require "bundler/setup"
require "rspec/trace"
require "rspec/snapshot"

RSPEC_ROOT = File.dirname __FILE__

RSpec.configure do |config|
  config.snapshot_dir = "spec/fixtures/snapshots"

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
end
