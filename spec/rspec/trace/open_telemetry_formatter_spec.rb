require "timecop"

module RSpec
  module Trace
    RSpec.describe OpenTelemetryFormatter do
      let(:stdin) { instance_double(IO) }
      let(:process) { instance_double(Subprocess::Process, stdin: stdin) }
      let(:formatter) { described_class.new(nil) }

      before do
        allow(Subprocess::Process).to receive(:new).and_return(process)
        Timecop.freeze
        # This is evil
        allow(Time).to receive(:now_without_mock_time).and_return(Time.now)
      end

      it "constructs a formatter to output to an rspec-trace-consumer process" do
        expect(formatter.output).to eq(stdin)
      end

      it "prints an output object and waits for the process upon receiving the stop notification", :aggregate_failures do
        expect(process).to receive(:wait)
        expect(stdin).to receive(:puts).with(JSON.dump({timestamp: Time.now.as_json, event: "stop"}))
        formatter.stop(nil)
      end
    end
  end
end
