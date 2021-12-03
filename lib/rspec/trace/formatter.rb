# frozen_string_literal: true

require "active_support/time"
require "active_support/json"
require "rspec/core"
require "rspec/core/formatters/base_text_formatter"

require_relative "version"

module RSpec
  module Trace
    class Formatter < RSpec::Core::Formatters::BaseFormatter
      RSpec::Core::Formatters.register(
        self,
        :start,
        :example_group_started, :example_group_finished,
        :example_started, :example_passed, :example_pending, :example_failed,
        :stop
      )

      def start(notification)
        start_time = current_time
        output.puts(JSON.dump({
          timestamp: format_time(start_time - notification.load_time.seconds),
          event: :initiated
        }))
        output.puts(JSON.dump({
          timestamp: format_time(start_time),
          event: :start,
          count: notification.count
        }))
      end

      def example_group_started(notification)
        output.puts(JSON.dump({
          timestamp: current_timestamp,
          event: :example_group_started,
          group: notification.group.description
        }))
      end

      def example_group_finished(notification)
        output.puts(JSON.dump({
          timestamp: current_timestamp,
          event: :example_group_finished,
          group: notification.group.description
        }))
      end

      def example_started(notification)
        output.puts(JSON.dump({
          timestamp: current_timestamp,
          event: :example_started,
          example: notification.example.description
        }))
      end

      def example_passed(notification)
        output.puts(JSON.dump({
          timestamp: current_timestamp,
          event: :example_passed,
          example: notification.example.description
        }))
      end

      def example_pending(notification)
        output.puts(JSON.dump({
          timestamp: current_timestamp,
          event: :example_pending,
          example: notification.example.description
        }))
      end

      def example_failed(notification)
        output.puts(JSON.dump({
          timestamp: current_timestamp,
          event: :example_failed,
          example: notification.example.description,
          exception: {
            message: notification.example.exception.message,
            type: notification.example.exception.class.name,
            backtrace: notification.example.exception.full_message(highlight: false, order: :top).encode("UTF-8", invalid: :replace, undef: :replace, replace: "�")
          }
        }))
      end

      def stop(_notification)
        output.puts(JSON.dump({timestamp: current_timestamp, event: :stop}))
      end

      private

      def format_time(time)
        time.xmlschema(3)
      end

      def current_time
        if defined?(Timecop)
          Time.now_without_mock_time
        else
          Time.now
        end
      end

      def current_timestamp
        format_time(current_time)
      end
    end
  end
end
