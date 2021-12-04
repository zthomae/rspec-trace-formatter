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
          c.service_name = ENV.fetch("RSPEC_TRACE_FORMATTER_SERVICE_NAME", "rspec")
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
          when :initiated
            root_span_name = ENV.fetch("RSPEC_TRACE_FORMATTER_ROOT_SPAN_NAME", "rspec")
            create_span(name: root_span_name, timestamp: event[:timestamp])
            create_span(name: "examples loading", timestamp: event[:timestamp]) do |span|
              span.add_attributes("rspec.type" => "loading")
            end
          when :start
            complete_span(timestamp: event[:timestamp])
            create_span(name: "examples running", timestamp: event[:timestamp]) do |span|
              add_attributes_to_span(
                span: span,
                attributes: {count: event[:count], type: "suite"},
                attribute_prefix: "rspec"
              )
            end
          when :example_group_started
            create_span(name: event.dig(:group, :description), timestamp: event[:timestamp]) do |span|
              add_attributes_to_span(
                span: span,
                attributes: event[:group].merge(type: "example_group"),
                attribute_prefix: "rspec",
                exclude_attributes: [:description]
              )
            end
          when :example_group_finished
            complete_span(timestamp: event[:timestamp])
          when :example_started
            create_span(name: event.dig(:example, :description), timestamp: event[:timestamp]) do |span|
              add_attributes_to_span(
                span: span,
                attributes: event[:example].merge(type: "example"),
                attribute_prefix: "rspec",
                exclude_attributes: [:description]
              )
            end
          when :example_passed
            complete_span(timestamp: event[:timestamp]) do |span|
              add_attributes_to_span(
                span: span,
                attributes: event.dig(:example, :result),
                attribute_prefix: "rspec.result"
              )
            end
          when :example_pending
            complete_span(timestamp: event[:timestamp]) do |span|
              add_attributes_to_span(
                span: span,
                attributes: event.dig(:example, :result),
                attribute_prefix: "rspec.result"
              )
            end
          when :example_failed
            complete_span(timestamp: event[:timestamp]) do |span|
              add_attributes_to_span(
                span: span,
                attributes: event.dig(:example, :result),
                attribute_prefix: "rspec.result"
              )
              event_attributes = {
                "exception.type" => event.dig(:exception, :type),
                "exception.message" => event.dig(:exception, :message),
                "exception.stacktrace" => event.dig(:exception, :backtrace)
              }
              span.add_event("exception", attributes: event_attributes, timestamp: event[:timestamp])
              span.status = OpenTelemetry::Trace::Status.error
            end
          when :stop
            complete_span(timestamp: event[:timestamp]) until @spans.empty?
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

      def add_attributes_to_span(span:, attributes:, attribute_prefix: nil, exclude_attributes: [])
        attributes_for_span = attributes.map do |key, value|
          next if value.nil? || exclude_attributes.include?(key)

          full_key = attribute_prefix ? "#{attribute_prefix}.#{key}" : key.to_s
          [full_key, value]
        end.compact.to_h

        span.add_attributes(attributes_for_span)
      end
    end
  end
end
