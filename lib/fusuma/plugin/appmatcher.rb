# frozen_string_literal: true

require 'fusuma/plugin/appmatcher/version'

require_relative 'appmatcher/x11.rb'
require_relative 'appmatcher/gnome.rb'

module Fusuma
  module Plugin
    module Appmatcher
      module_function

      # @return [Class]
      def backend_klass
        if ENV['DESKTOP_SESSION'] == 'ubuntu-wayland'
          Fusuma::Plugin::Appmatcher::Gnome
        else
          Fusuma::Plugin::Appmatcher::X11
        end
      end
    end
  end
end
