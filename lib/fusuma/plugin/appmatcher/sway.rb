# frozen_string_literal: true

require "open3"
require "json"
require_relative "user_switcher"
require "fusuma/multi_logger"
require "fusuma/custom_process"

module Fusuma
  module Plugin
    module Appmatcher
      # Search Active Window's Name for Sway (wlroots-based compositor)
      class Sway
        include UserSwitcher

        attr_reader :reader, :writer

        # Check if swaymsg command is available
        # @return [Boolean]
        def self.available?
          system("which swaymsg > /dev/null 2>&1")
        end

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

        # Look up application name using swaymsg
        class Matcher
          def initialize
            @cache = {}
          end

          # @return [Array<String>]
          def running_applications
            tree = fetch_tree
            collect_app_names(tree).compact.uniq
          rescue => e
            MultiLogger.error "Failed to get running applications: #{e.message}"
            []
          end

          # @return [String]
          # @return [NilClass]
          def active_application
            tree = fetch_tree
            focused = find_focused_node(tree)
            extract_app_name(focused)
          rescue => e
            MultiLogger.error "Failed to get active application: #{e.message}"
            nil
          end

          # Subscribe to window focus events and yield application name on change
          def on_active_application_changed
            subscribe_window_events do |event|
              next unless event["change"] == "focus"

              container = event["container"]
              app_name = extract_app_name(container)
              yield(app_name || "NOT FOUND") if app_name || container
            end
          rescue => e
            MultiLogger.error "Sway subscription error: #{e.message}"
            sleep 1
            retry
          end

          private

          # Fetch the current window tree from sway
          # @return [Hash]
          def fetch_tree
            output = `swaymsg -t get_tree`
            JSON.parse(output)
          end

          # Subscribe to sway window events
          def subscribe_window_events
            cmd = ["swaymsg", "-m", "-t", "subscribe", '["window"]']
            Open3.popen3(*cmd) do |stdin, stdout, stderr, wait_thr|
              stdin.close
              stdout.each_line do |line|
                event = JSON.parse(line)
                yield event
              rescue JSON::ParserError => e
                MultiLogger.warn "Failed to parse sway event: #{e.message}"
              end
              MultiLogger.error stderr.read if stdout.eof?
            end
          rescue Errno::ENOENT
            MultiLogger.error "swaymsg command not found. Is sway installed?"
            raise
          end

          # Recursively find the focused node in the tree
          # @param node [Hash]
          # @return [Hash, nil]
          def find_focused_node(node)
            return node if node["focused"]

            # Check regular nodes
            (node["nodes"] || []).each do |child|
              result = find_focused_node(child)
              return result if result
            end

            # Check floating nodes
            (node["floating_nodes"] || []).each do |child|
              result = find_focused_node(child)
              return result if result
            end

            nil
          end

          # Extract application name from container
          # Wayland native apps use app_id, XWayland apps use window_properties.class
          # @param container [Hash, nil]
          # @return [String, nil]
          def extract_app_name(container)
            return nil unless container

            # Wayland native application
            app_id = container["app_id"]
            return app_id if app_id && !app_id.empty?

            # XWayland application (fallback)
            window_props = container["window_properties"]
            window_props&.dig("class")
          end

          # Recursively collect all application names from the tree
          # @param node [Hash]
          # @param apps [Array<String>]
          # @return [Array<String>]
          def collect_app_names(node, apps = [])
            app_name = extract_app_name(node)
            apps << app_name if app_name

            (node["nodes"] || []).each { |child| collect_app_names(child, apps) }
            (node["floating_nodes"] || []).each { |child| collect_app_names(child, apps) }

            apps
          end
        end
      end
    end
  end
end
