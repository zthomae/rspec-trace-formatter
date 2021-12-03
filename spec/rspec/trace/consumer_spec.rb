require "opentelemetry/sdk"

module RSpec
  module Trace
    class TestSpanExporter
      def initialize
        @stopped = false
        @output = []
      end

      def output
        @output.join("\n")
      end

      def export(spans, timeout: nil)
        return OpenTelemetry::SDK::Trace::Export::FAILURE if @stopped

        Array(spans).each do |s|
          @output.append(s.as_json.pretty_inspect)
        end

        OpenTelemetry::SDK::Trace::Export::SUCCESS
      end

      def force_flush(timeout: nil)
        OpenTelemetry::SDK::Trace::Export::SUCCESS
      end

      def shutdown(timeout: nil)
        @stopped = true
        OpenTelemetry::SDK::Trace::Export::SUCCESS
      end
    end

    class IdGenerator
      def initialize
        @last_trace_id = 0
        @last_span_id = 0
      end

      def generate_trace_id
        (@last_trace_id += 1).to_s
      end

      def generate_span_id
        (@last_span_id += 1).to_s
      end
    end

    RSpec.describe Consumer do
      let(:input) do
        StringIO.new(
          File.read(
            File.join(RSPEC_ROOT, "fixtures", "example_trace_events.jsonl")
          )
        )
      end

      before do
        stub_const("RSpec::Trace::VERSION", "0.1.2.pre.version")
      end

      it "generates spans matching the snapshot" do
        consumer = described_class.new(input)

        OpenTelemetry.tracer_provider.id_generator = IdGenerator.new

        # TODO: Anything but this
        span_exporter = TestSpanExporter.new
        OpenTelemetry.tracer_provider.instance_variable_set(
          :@span_processors,
          [OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(span_exporter)]
        )
        OpenTelemetry.tracer_provider.instance_variable_set(
          :@resource,
          OpenTelemetry::SDK::Resources::Resource.create({"test.attribute" => 1})
        )

        allow(consumer).to receive(:exit)

        consumer.run

        expect(span_exporter.output).to match_snapshot("consumer_events")
      end
    end
  end
end
