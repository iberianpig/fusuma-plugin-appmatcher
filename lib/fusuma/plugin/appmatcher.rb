# frozen_string_literal: true

require 'fusuma/plugin/appmatcher/version'

require_relative 'appmatcher/x11'
require_relative 'appmatcher/gnome'

module Fusuma
  module Plugin
    module Appmatcher
      module_function

      # @return [Class]
      def backend_klass
        if ENV['DESKTOP_SESSION'] == 'ubuntu-wayland'
          Gnome
        else
          X11
        end
      end
    end
  end
end
