# frozen_string_literal: true

require "open3"
require_relative "./user_switcher"
require "fusuma/multi_logger"
require "fusuma/custom_process"

module Fusuma
  module Plugin
    module Appmatcher
      # Dummy for unsupported Backend
      class UnsupportedBackend
        include UserSwitcher

        attr_reader :reader, :writer

        def initialize
          # need IO object for IO.select()
          @reader, @writer = IO.pipe
        end

        # fork process and watch signal
        # @return [Integer] Process id
        def watch_start
          @watch_start ||= begin
            pid = as_user(proctitle: self.class.name.underscore) do
              @reader.close
              sleep # stop indefinitely without using CPU
            end
            pid
          end
        end

        class Matcher
          def initialize
          end

          def running_applications
            warn
            nil
          end

          def active_application
            warn
            nil
          end

          private

          def warn
            MultiLogger.warn(
              <<~MSG
                appmatcher doesn't support
                XDG_CURRENT_DESKTOP: '#{Appmatcher.xdg_current_desktop}'
                XDG_SESSION_TYPE: '#{Appmatcher.xdg_session_type}'

                using dummy backend instead
              MSG
            )
          end
        end
      end
    end
  end
end
