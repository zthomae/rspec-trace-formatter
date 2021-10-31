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
        output.puts(JSON.dump({
          timestamp: current_timestamp,
          event: :start,
          count: notification.count,
          load_time: notification.load_time
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
          message_lines: notification.example.message_lines,
          backtrace: notification.example.exception.backtrace
        }))
      end

      def stop(_notification)
        output.puts(JSON.dump({timestamp: current_timestamp, event: :stop}))
      end

      private

      def current_timestamp
        Time.current.as_json
      end
    end
  end
end
