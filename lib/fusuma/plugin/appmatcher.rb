# frozen_string_literal: true

require "fusuma/plugin/appmatcher/version"

require "fusuma/plugin/appmatcher/x11"
require "fusuma/plugin/appmatcher/gnome_extension"
require "fusuma/plugin/appmatcher/gnome_extensions/installer"
require "fusuma/plugin/appmatcher/unsupported_backend"

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
          case xdg_current_desktop
          when /GNOME/
            if GnomeExtensions::Installer.new.enabled?
              return GnomeExtension
            else
              MultiLogger.warn "Appmatcher Gnome Shell Extension is NOT enabled"
              MultiLogger.warn "Please enable it by running the following command:"
              MultiLogger.warn ""
              MultiLogger.warn "$ fusuma-appmatcher --install-gnome-extension"
              MultiLogger.warn ""
            end
          end
        end

        MultiLogger.warn "appmatcher doesn't support"
        UnsupportedBackend
      end

      def xdg_session_type
        ENV.fetch("XDG_SESSION_TYPE", "")
      end

      def xdg_current_desktop
        ENV.fetch("XDG_CURRENT_DESKTOP", "")
      end
    end
  end
end
