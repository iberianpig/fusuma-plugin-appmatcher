# frozen_string_literal: true

require "json"
require "open3"
require_relative "user_switcher"
require "fusuma/multi_logger"
require "fusuma/custom_process"

module Fusuma
  module Plugin
    module Appmatcher
      # Search the active window's application for the Niri compositor.
      class Niri
        include UserSwitcher

        attr_reader :reader, :writer

        def self.available?
          ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? do |dir|
            path = File.join(dir, "niri")
            File.executable?(path) && !File.directory?(path)
          end
        end

        def initialize
          @reader, @writer = IO.pipe
        end

        def watch_start
          as_user(proctitle: self.class.name.underscore) do |_user|
            @reader.close
            register_on_application_changed(Matcher.new)
          end
        end

        private

        def register_on_application_changed(matcher)
          @writer.puts(matcher.active_application || "NOT FOUND")
          matcher.on_active_application_changed { |name| notify(name) }
        end

        def notify(name)
          @writer.puts(name)
        rescue Errno::EPIPE
          exit 0
        rescue => e
          MultiLogger.error e.message
          exit 1
        end

        class Matcher
          def running_applications
            windows.map { |window| window["app_id"] }.compact.uniq
          rescue JSON::ParserError, Errno::ENOENT
            []
          end

          def active_application
            active_window&.fetch("app_id", nil)
          rescue JSON::ParserError, Errno::ENOENT
            nil
          end

          def on_active_application_changed
            last = Object.new
            subscribe_events do
              application = active_application
              next if application == last

              last = application
              yield(application || "NOT FOUND")
            end
          rescue => e
            MultiLogger.error "Niri subscription error: #{e.message}"
            sleep 1
            retry
          end

          private

          def windows
            stdout, _stderr, status = Open3.capture3("niri", "msg", "-j", "windows")
            return [] unless status.success? && !stdout.empty?

            JSON.parse(stdout)
          end

          def active_window
            windows.find { |window| window["is_focused"] }
          end

          def subscribe_events
            Open3.popen3("niri", "msg", "-j", "event-stream") do |stdin, stdout, stderr, _wait_thr|
              stdin.close
              stdout.each_line do |line|
                JSON.parse(line)
                yield
              rescue JSON::ParserError => e
                MultiLogger.warn "Failed to parse Niri event: #{e.message}"
              end
              raise "niri event-stream exited: #{stderr.read}"
            end
          rescue Errno::ENOENT
            MultiLogger.error "niri command not found. Is Niri installed?"
            raise
          end
        end
      end
    end
  end
end
