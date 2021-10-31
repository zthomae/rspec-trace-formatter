# frozen_string_literal: true

require "subprocess"
require_relative "formatter"

module RSpec
  module Trace
    class OpenTelemetryFormatter < Formatter
      RSpec::Core::Formatters.register(
        self,
        :start,
        :example_group_started, :example_group_finished,
        :example_started, :example_passed, :example_pending, :example_failed,
        :stop
      )

      def initialize(output)
        @process = Subprocess::Process.new(["rspec-trace-consumer"], {stdin: Subprocess::PIPE})
        super(@process.stdin)
      end

      def stop(notification)
        super(notification)

        @process.wait
      end
    end
  end
end
