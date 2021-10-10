# frozen_string_literal: true

require "opentelemetry/sdk"
require "opentelemetry/exporter/otlp"
require "rspec/core"
require "rspec/core/formatters/base_text_formatter"

require_relative "version"

module RSpec
  module Trace
    class Formatter < RSpec::Core::Formatters::BaseTextFormatter
      RSpec::Core::Formatters.register(
        self,
        :start,
        :example_group_started, :example_group_finished,
        :example_started, :example_passed, :example_pending, :example_failed,
        :stop
      )

      def start(notification)
        # TODO: This is a bad idea...
        OpenTelemetry::SDK.configure do |c|
          c.service_name = "rspec" # TODO: Configure
        end
        @tracer_provider = OpenTelemetry.tracer_provider
        @tracer_provider.sampler = OpenTelemetry::SDK::Trace::Samplers::ALWAYS_ON
        @tracer = @tracer_provider.tracer("rspec-trace-formatter", RSpec::Trace::VERSION)
        # TODO:
        # - Configure span name
        # - Use load time to backpedal start time?
        @spans = []
        @current_span_key = OpenTelemetry::Trace.const_get(:CURRENT_SPAN_KEY)
        @contexts = [OpenTelemetry::Context.empty]
        @tokens = []
        @spans = [@tracer.start_span("rspec", kind: :server).add_attributes("count" => notification.count)]
      end

      def example_group_started(notification)
        create_span(notification.group.description)
      end

      def example_group_finished(notification)
        complete_span
      end

      def example_started(notification)
        create_span(notification.example.description)
      end

      def example_passed(notification)
        complete_span
      end

      def example_pending(notification)
        complete_span do |span|
          span.add_event("Pending")
        end
      end

      def example_failed(notification)
        complete_span do |span|
          span.status = OpenTelemetry::Trace::Status.error
        end
      end

      def stop(notification)
        @spans.pop.finish
        @tracer_provider.force_flush
      end

      private

      def create_span(name, kind: :internal)
        @tracer.start_span(name, with_parent: @contexts.last, kind: kind).tap do |span|
          @spans.push(span)
          @contexts.push(@contexts.last.set_value(@current_span_key, span))
          @tokens.push(OpenTelemetry::Context.attach(@contexts.last))
        end
      end

      def complete_span
        @spans.pop.tap do |span|
          yield span if block_given?
          span.finish
          @contexts.pop
          OpenTelemetry::Context.detach(@tokens.pop)
        end
      end
    end
  end
end
