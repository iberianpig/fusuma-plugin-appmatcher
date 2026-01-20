# frozen_string_literal: true

require "socket"
require "json"
require_relative "user_switcher"
require "fusuma/multi_logger"
require "fusuma/custom_process"

module Fusuma
  module Plugin
    module Appmatcher
      # Search Active Window's Name for Hyprland
      class Hyprland
        include UserSwitcher

        attr_reader :reader, :writer

        def initialize
          @reader, @writer = IO.pipe
        end

        # fork process and watch signal
        # @return [Integer] Process id
        def watch_start
          as_user(proctitle: self.class.name.underscore) do |_user|
            @reader.close
            register_on_application_changed(Matcher.new)
          end
        end

        private

        def register_on_application_changed(matcher)
          @writer.puts(matcher.active_application || "NOT FOUND")

          matcher.on_active_application_changed do |name|
            notify(name)
          end
        end

        def notify(name)
          @writer.puts(name)
        rescue Errno::EPIPE
          exit 0
        rescue => e
          MultiLogger.error e.message
          exit 1
        end

        # Look up application name using hyprctl
        class Matcher
          ACTIVEWINDOW_EVENT = "activewindow"

          # @return [Array<String>]
          def running_applications
            output = `hyprctl clients -j 2>/dev/null`
            return [] if output.empty?
            JSON.parse(output).map { |c| c["class"] }.compact.uniq
          rescue JSON::ParserError
            []
          end

          # @return [String, nil]
          def active_application
            output = `hyprctl -j activewindow 2>/dev/null`
            return nil if output.empty? || output.strip == "{}"
            JSON.parse(output)["class"]
          rescue JSON::ParserError
            nil
          end

          def on_active_application_changed
            socket = connect_to_socket2
            return unless socket

            loop do
              line = socket.gets
              break unless line

              event, data = line.chomp.split(">>", 2)
              next unless event == ACTIVEWINDOW_EVENT

              window_class, _window_title = data.split(",", 2)
              yield(window_class.to_s.empty? ? "NOT FOUND" : window_class)
            end
          rescue Errno::ECONNRESET, Errno::EPIPE, IOError
            # socket disconnected
          ensure
            socket&.close
          end

          private

          # @return [String, nil]
          def find_socket_path
            instance_sig = ENV["HYPRLAND_INSTANCE_SIGNATURE"]
            return nil unless instance_sig

            xdg_runtime = ENV.fetch("XDG_RUNTIME_DIR", "/tmp")
            [
              File.join(xdg_runtime, "hypr", instance_sig, ".socket2.sock"),
              File.join("/tmp", "hypr", instance_sig, ".socket2.sock")
            ].find { |p| File.exist?(p) }
          end

          # @return [UNIXSocket, nil]
          def connect_to_socket2
            path = find_socket_path
            return nil unless path
            UNIXSocket.new(path)
          rescue Errno::ENOENT, Errno::ECONNREFUSED
            nil
          end
        end
      end
    end
  end
end
