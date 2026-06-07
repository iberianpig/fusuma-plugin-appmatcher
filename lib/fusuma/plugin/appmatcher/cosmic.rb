# frozen_string_literal: true

require "open3"
require "json"
require_relative "user_switcher"
require "fusuma/multi_logger"
require "fusuma/custom_process"

module Fusuma
  module Plugin
    module Appmatcher
      # Search Active Window's Name for COSMIC desktop via cos-cli (third-party).
      # cos-cli must be installed separately:
      #   cargo install --git https://github.com/estin/cos-cli
      class Cosmic
        include UserSwitcher

        attr_reader :reader, :writer

        # @return [Boolean]
        def self.available?
          stdout, _stderr, status = Open3.capture3("which", "cos-cli")
          status.success? && !stdout.strip.empty?
        rescue Errno::ENOENT
          false
        end

        def initialize
          @reader, @writer = IO.pipe
        end

        class Matcher
          # @return [String, nil]
          def active_application
            state = fetch_info
            extract_activated_app_id(state)
          end

          # @return [Array<String>]
          def running_applications
            state = fetch_info
            return [] unless state
            (state["apps"] || []).map { |a| a["app_id"] }.compact.uniq
          end

          # Sentinel value distinct from nil, so the first iteration always
          # yields (otherwise initial nil == nil would skip yielding NOT FOUND).
          UNSET = Object.new.freeze
          private_constant :UNSET

          def on_active_application_changed
            last = UNSET
            subscribe_state_change do |state|
              app_id = extract_activated_app_id(state)
              next if app_id == last
              last = app_id
              yield(app_id || "NOT FOUND")
            end
          rescue => e
            MultiLogger.error "Cosmic subscription error: #{e.message}"
            sleep 1
            retry
          end

          private

          # @return [Hash, nil]
          def fetch_info
            stdout, _stderr, status = Open3.capture3("cos-cli", "info", "--json")
            return nil unless status.success? && !stdout.empty?
            JSON.parse(stdout)
          rescue JSON::ParserError, Errno::ENOENT
            nil
          end

          # @param state [Hash, nil]
          # @return [String, nil]
          def extract_activated_app_id(state)
            return nil unless state
            apps = state["apps"] || []
            focused = apps.find { |a| (a["state"] || []).include?("activated") }
            focused && focused["app_id"]
          end

          def subscribe_state_change
            Open3.popen3("cos-cli", "serve") do |stdin, stdout, stderr, _wait_thr|
              stdin.close
              stdout.each_line do |line|
                msg = JSON.parse(line)
                next unless msg["method"] == "state_change"
                state = msg.dig("params", "state")
                yield state if state
              rescue JSON::ParserError => e
                MultiLogger.warn "Failed to parse cos-cli message: #{e.message}"
              end
              MultiLogger.error stderr.read if stdout.eof?
            end
          rescue Errno::ENOENT
            MultiLogger.error "cos-cli command not found. Install with: cargo install --git https://github.com/estin/cos-cli"
            raise
          end
        end
      end
    end
  end
end
