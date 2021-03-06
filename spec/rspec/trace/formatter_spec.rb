require "timecop"

module RSpec
  module Trace
    RSpec.describe Formatter do
      let(:formatter) { described_class.new(StringIO.new) }
      let(:output_string) { formatter.output.string }

      before do
        Timecop.freeze
        # This is evil
        allow(Time).to receive(:now_without_mock_time).and_return(Time.now)
      end

      def expect_output_objects(*expected_objects)
        actual_objects = output_string.lines.map { |line| JSON.parse(line, symbolize_names: true) }
        expect(actual_objects).to eq(expected_objects)
      end

      it "outputs a correct start notification" do
        notification = RSpec::Core::Notifications::StartNotification.new(
          152,
          517.2
        )
        current_time = Time.now
        start_time = Time.now - notification.load_time.seconds
        formatter.start(notification)
        expect_output_objects(
          {timestamp: start_time.as_json, event: "initiated"},
          {timestamp: current_time.as_json, event: "start", count: 152}
        )
      end

      it "outputs a correct example_group_started notification" do
        example_group = double(
          RSpec::Core::ExampleGroup.class.name,
          description: "The best example group",
          described_class: "FooBar",
          file_path: "/path/to/foo_bar.rb",
          location: "/path/to/foo_bar.rb:43"
        )
        notification = RSpec::Core::Notifications::GroupNotification.new(example_group)
        formatter.example_group_started(notification)
        expect_output_objects(
          {
            timestamp: Time.now.as_json,
            event: "example_group_started",
            group: {
              description: "The best example group",
              described_class: "FooBar",
              file_path: "/path/to/foo_bar.rb",
              location: "/path/to/foo_bar.rb:43"
            }
          }
        )
      end

      it "outputs a correct example_group_finished notification" do
        example_group = double(
          RSpec::Core::ExampleGroup.class.name,
          description: "The worst example group",
          described_class: "BarBaz",
          file_path: "/path/to/bar_baz.rb",
          location: "/path/to/bar_baz.rb:932"
        )
        notification = RSpec::Core::Notifications::GroupNotification.new(example_group)
        formatter.example_group_finished(notification)
        expect_output_objects(
          {
            timestamp: Time.now.as_json,
            event: "example_group_finished",
            group: {
              description: "The worst example group",
              described_class: "BarBaz",
              file_path: "/path/to/bar_baz.rb",
              location: "/path/to/bar_baz.rb:932"
            }
          }
        )
      end

      it "outputs a correct example_started notification" do
        example = double(
          RSpec::Core::Example.class.name,
          description: "Example 1",
          full_description: "This is Example 1",
          file_path: "/path/to/file.rb",
          location: "/path/to/file.rb:123"
        )
        notification = double(
          RSpec::Core::Notifications::ExampleNotification.class.name,
          example: example
        )
        formatter.example_started(notification)
        expect_output_objects(
          {
            timestamp: Time.now.as_json,
            event: "example_started",
            example: {
              description: "Example 1",
              full_description: "This is Example 1",
              file_path: "/path/to/file.rb",
              location: "/path/to/file.rb:123"
            }
          }
        )
      end

      it "outputs a correct example_passed notification" do
        execution_result = double(
          RSpec::Core::Example::ExecutionResult.class.name,
          status: :passed,
          pending_message: nil,
          pending_fixed: nil
        )
        example = double(
          RSpec::Core::Example.class.name,
          description: "Example 1",
          full_description: "This is Example 1",
          file_path: "/path/to/file.rb",
          location: "/path/to/file.rb:123",
          execution_result: execution_result
        )
        notification = double(
          RSpec::Core::Notifications::ExampleNotification.class.name,
          example: example
        )
        formatter.example_passed(notification)
        expect_output_objects(
          {
            timestamp: Time.now.as_json,
            event: "example_passed",
            example: {
              description: "Example 1",
              full_description: "This is Example 1",
              file_path: "/path/to/file.rb",
              location: "/path/to/file.rb:123",
              result: {
                status: "passed",
                pending_message: nil,
                pending_fixed: nil
              }
            }
          }
        )
      end

      it "outputs a correct example_pending notification" do
        execution_result = double(
          RSpec::Core::Example::ExecutionResult.class.name,
          status: :pending,
          pending_message: "Not ready to run this",
          pending_fixed: false
        )
        example = double(
          RSpec::Core::Example.class.name,
          description: "Example 1",
          full_description: "This is Example 1",
          file_path: "/path/to/file.rb",
          location: "/path/to/file.rb:123",
          execution_result: execution_result
        )
        notification = double(
          RSpec::Core::Notifications::ExampleNotification.class.name,
          example: example
        )
        formatter.example_pending(notification)
        expect_output_objects(
          {
            timestamp: Time.now.as_json,
            event: "example_pending",
            example: {
              description: "Example 1",
              full_description: "This is Example 1",
              file_path: "/path/to/file.rb",
              location: "/path/to/file.rb:123",
              result: {
                status: "pending",
                pending_message: "Not ready to run this",
                pending_fixed: false
              }
            }
          }
        )
      end

      it "outputs a correct example_failed notification" do
        execution_result = double(
          RSpec::Core::Example::ExecutionResult.class.name,
          status: :failed,
          pending_message: nil,
          pending_fixed: nil
        )
        exception = RuntimeError.new("Something went wrong")
        exception.set_backtrace(["/path/to/foo.rb:32", "/path/to/bar.rb:512"])
        example = double(
          RSpec::Core::Example.class.name,
          description: "Example 1",
          exception: exception,
          full_description: "This is Example 1",
          file_path: "/path/to/file.rb",
          location: "/path/to/file.rb:123",
          execution_result: execution_result
        )
        notification = double(
          RSpec::Core::Notifications::ExampleNotification.class.name,
          example: example
        )
        formatter.example_failed(notification)
        expect_output_objects(
          {
            timestamp: Time.now.as_json,
            event: "example_failed",
            example: {
              description: "Example 1",
              full_description: "This is Example 1",
              file_path: "/path/to/file.rb",
              location: "/path/to/file.rb:123",
              result: {
                status: "failed",
                pending_message: nil,
                pending_fixed: nil
              }
            },
            exception: {
              message: "Something went wrong",
              type: "RuntimeError",
              backtrace: "/path/to/foo.rb:32: Something went wrong (RuntimeError)\n\tfrom /path/to/bar.rb:512\n"
            }
          }
        )
      end

      it "outputs a correct stop notification" do
        formatter.stop(nil)
        expect_output_objects(
          {timestamp: Time.now.as_json, event: "stop"}
        )
      end
    end
  end
end
