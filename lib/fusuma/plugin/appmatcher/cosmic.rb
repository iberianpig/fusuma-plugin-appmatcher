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
        end
      end
    end
  end
end
