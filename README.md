# rspec-trace-formatter

An [RSpec](https://rspec.info) formatter for constructing [trace data](https://opentelemetry.io/docs/concepts/data-sources/#traces) from your specs.
This library is inspired by [go-test-trace](https://github.com/rakyll/go-test-trace).

## Why Would I Use This?

Collecting data from your RSpec tests may be useful to you for a number of reasons:

1. You'd like to see statistical trends in test runtimes, or in your CI/CD pipeline as a whole
2. You'd like a dataset containing pass/fail statuses for all tests to help hunt down flakes
4. Other things that I can't think of

Traces aren't the only choice for collecting this data, but they are a reasonable one.
With concepts like test files and example groups, test execution naturally maps onto a trace tree.
The flexibility of tools like [OpenTelemetry](https://opentelemetry.io) when it comes to including arbitrary key-value attribute pairings is useful when instrumenting a library like RSpec because we can preserve as much context about the tests as we like.
And this test data isn't likely to be valuable long-term, so the standard retention periods for traces are likely to be acceptable.

## What's In The Box?

There are three main parts to this library.

### `RSpec::Trace::Formatter`

`RSpec::Trace::Formatter` is an RSpec formatter that emits events containing data that's relevant for constructing traces.
This formatter doesn't create traces -- it only outputs JSON events.

This formatter emits events for the most significant lifecycle events in an RSpec suite: the start of the suite, the start/end of each example and example group, and the end of the suite.
Because all events are timestamped, you can expect accurate timing data.
It also collects data about the names of the examples and example groups that are run, as well as useful facts like file locations, pass/fail status, &etc.

The event format is designed to be redundant when providing facts about examples and example groups, so as to be less prescriptive about how you consume them.
This may not be the best decision, but it seemed the right way.

### `rspec-trace-consumer`

`rspec-trace-consumer` is a script that reads events created by `RSpec::Trace::Formatter` from standard input and emits trace data to an [OpenTelemetry collector](https://opentelemetry.io/docs/collector/).
The OpenTelemetry SDK can be configured using the standard [`OTEL_*` environment variables](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/sdk-environment-variables.md).

If not set by the `OTEL_SERVICE_NAME` environment variable, the service name will be set to `rspec`.
The name of the root span defaults to "rspec", but you can change that as well with the `RSPEC_TRACE_FORMATTER_ROOT_SPAN_NAME` environment variable.

This script uses the [`AlwaysOn` sampler](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/sdk.md#alwayson) to ensure that no data is ever discarded.

### `RSpec::Trace::OpenTelemetryFormatter`

`RSpec::Trace::OpenTelemetryFormatter` is a separate RSpec formatter that combines the two pieces above to collect trace events from RSpec tests _and_ send them to an OpenTelemetry collector.

Because this uses the (very nice!) [subprocess library](https://github.com/stripe/subprocess), it only works on Ruby platforms where `fork` is supported.
If you're running in an environment where this isn't supported (e.g. JRuby) you won't be able to use this.
However, the rest of this library is _expected_ to work for you, and [specifying an `--out` target for `RSpec::Trace::Formatter`](https://relishapp.com/rspec/rspec-core/v/3-10/docs/command-line/format-option) may make this easier.

## How Do I Use It?

You can install this gem by adding the `rspec-trace-formatter` (along with the necessary OpenTelemetry dependencies, if they aren't already included) to your `Gemfile` and running `bundle install`.
For example:

```ruby
group :test do
  gem "rspec-trace-formatter"
  gem "opentelemetry-api", "~> 1.0"
  gem "opentelemetry-exporter-otlp", "~> 0.20.0"
end
```

This library should be used like [any other RSpec formatter](https://relishapp.com/rspec/rspec-core/v/3-10/docs/command-line/format-option), with the assistance of any environment variables that you need to control the OpenTelemetry data.

Example of using the `RSpec::Trace::OpenTelemetryFormatter` with representative environment variables set:

```bash
OTEL_TRACES_EXPORTER=console bundle exec rspec --format RSpec::Trace::OpenTelemetryFormatter
```

Example of running the `RSpec::Trace::Formatter` by itself and sending the output to `rspec-trace-consumer` separately (in a way that you can surely improve upon):

```bash
OTEL_TRACES_EXPORTER=console bundle exec rspec --format RSpec::Trace::Formatter --out /tmp/trace-events.jsonl

rspec-trace-consumer < /tmp/trace-events.jsonl
```

## How Do I Contribute?

Very carefully, I hope.

One notable fact is that we use [snapshot testing](https://github.com/levinmr/rspec-snapshot) for the class underpinning `rspec-trace-consumer`.
To keep this reliable, I've defined a custom OpenTelemetry span exporter that includes meaningful-enough data to test with and no execution-specific fields.

## What's Coming Next?

This does not yet support providing a [parent trace ID with an environment variable](https://github.com/open-telemetry/opentelemetry-specification/issues/740).
I haven't done it yet because it's not very helpful to me given my primary use case, but I'll add that soon enough.

The fixtures for the snapshot tests for the `Consumer` class are currently system-specific insofar as the exception stack traces are built from real exceptions that include paths from the Ruby installation that generated them.
Right now they come from my setup, so if anyone else regenerates the fixtures these paths will change.
I believe that the ideal way to fix this is to provide a containerized development environment for which these paths can be fixed for everyone.

## License

MIT
