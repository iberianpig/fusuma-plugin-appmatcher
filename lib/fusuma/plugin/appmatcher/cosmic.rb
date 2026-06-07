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
      end
    end
  end
end
