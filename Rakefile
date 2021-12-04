require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:test)
task default: :test

desc "Run the tests and update the snapshots"
task :update_snapshots do
  system("UPDATE_SNAPSHOTS=true rake test")
end

desc "Regenerates example fixtures for tests"
task :regenerate_examples do
  system("rspec --format RSpec::Trace::Formatter --out spec/fixtures/example_trace_events.jsonl examples")
end
