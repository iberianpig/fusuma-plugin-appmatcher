# frozen_string_literal: true

require 'fusuma/plugin/appmatcher/version'

require_relative 'appmatcher/x11'
require_relative 'appmatcher/gnome'

module Fusuma
  module Plugin
    # Detect focused applications.
    module Appmatcher
      module_function

      # @return [Class]
      def backend_klass
        case xdg_session_type
        when /x11/
          return X11
        when /wayland/
          return Gnome if xdg_current_desktop =~ /GNOME/
        end
        MultiLogger.error(
          <<~ERROR
            appmatcher doesn't support
            XDG_CURRENT_DESKTOP: '#{xdg_current_desktop}'
            XDG_SESSION_TYPE: '#{xdg_session_type}'"
          ERROR
        )
        exit 1
      end

      def xdg_session_type
        ENV.fetch('XDG_SESSION_TYPE', '')
      end

      def xdg_current_desktop
        ENV.fetch('XDG_CURRENT_DESKTOP', '')
      end
    end
  end
end
