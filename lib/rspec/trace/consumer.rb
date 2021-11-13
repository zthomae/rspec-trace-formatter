# frozen_string_literal: true

require "json"
require "opentelemetry/sdk"
require "opentelemetry/exporter/otlp"

module RSpec
  module Trace
    class Consumer
      def initialize(input)
        @input = input
        OpenTelemetry::SDK.configure do |c|
          c.service_name = "rspec" # TODO: Configure
        end
        @tracer_provider = OpenTelemetry.tracer_provider
        @tracer_provider.sampler = OpenTelemetry::SDK::Trace::Samplers::ALWAYS_ON
        @tracer = @tracer_provider.tracer("rspec-trace-formatter", RSpec::Trace::VERSION)
        @spans = []
        # TODO: Not this
        @current_span_key = OpenTelemetry::Trace.const_get(:CURRENT_SPAN_KEY)
        @contexts = [OpenTelemetry::Context.empty]
        @tokens = []
      end

      def run
        @input.each_line do |line|
          next if line.strip.empty?

          begin
            event = parse_event(line)
          rescue
            warn "invalid line: #{line}"
            next
          end

          case event[:event].to_sym
          when :start
            # TODO:
            # - Configure span name
            # - Use load time to backpedal start time?
            create_span(name: "rspec", timestamp: event[:timestamp]) do |span|
              span.add_attributes(
                "rspec.count" => event[:count],
                "rspec.load_time" => event[:load_time],
                "rspec.type" => "suite"
              )
            end
          when :example_group_started
            create_span(name: event[:group], timestamp: event[:timestamp]) do |span|
              span.add_attributes("rspec.type" => "example_group")
            end
          when :example_group_finished
            complete_span(timestamp: event[:timestamp])
          when :example_started
            create_span(name: event[:example], timestamp: event[:timestamp]) do |span|
              span.add_attributes("rspec.type" => "example")
            end
          when :example_passed
            complete_span(timestamp: event[:timestamp])
          when :example_pending
            complete_span(timestamp: event[:timestamp]) do |span|
              span.add_event("Pending")
            end
          when :example_failed
            complete_span(timestamp: event[:timestamp]) do |span|
              # TODO: Use error information
              span.status = OpenTelemetry::Trace::Status.error
            end
          when :stop
            @spans.pop.finish(end_timestamp: event[:timestamp])
            @tracer_provider.force_flush
            exit
          end
        end
      end

      private

      def parse_event(line)
        event = JSON.parse(line, symbolize_names: true)
        event[:timestamp] = Time.parse(event[:timestamp])
        event
      end

      def create_span(name:, timestamp:)
        @tracer.start_span(name, start_timestamp: timestamp, with_parent: @contexts.last).tap do |span|
          yield span if block_given?
          @spans.push(span)
          @contexts.push(@contexts.last.set_value(@current_span_key, span))
          @tokens.push(OpenTelemetry::Context.attach(@contexts.last))
        end
      end

      def complete_span(timestamp:)
        @spans.pop.tap do |span|
          yield span if block_given?
          span.finish(end_timestamp: timestamp)
          @contexts.pop
          OpenTelemetry::Context.detach(@tokens.pop)
        end
      end
    end
  end
end
