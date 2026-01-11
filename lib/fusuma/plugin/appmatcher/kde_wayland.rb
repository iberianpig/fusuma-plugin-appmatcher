# frozen_string_literal: true

require "dbus"
require_relative "user_switcher"
require "fusuma/multi_logger"

module Fusuma
  module Plugin
    module Appmatcher
      # Search Active Window's Name for KDE Wayland
      class KdeWayland
        include UserSwitcher

        attr_reader :reader, :writer

        def initialize
          @reader, @writer = IO.pipe
        end

        # fork process and watch DBus signals from KWin script
        # @return [Integer] Process id
        def watch_start
          as_user(proctitle: self.class.name.underscore) do |user|
            @reader.close
            ENV["DBUS_SESSION_BUS_ADDRESS"] = "unix:path=/run/user/#{user.uid}/bus"
            register_dbus_service
          end
        end

        private

        def register_dbus_service
          bus = DBus.session_bus
          service = bus.request_service("dev.iberianpig.Appmatcher.KDE")

          matcher = Matcher.new(@writer)
          service.export(matcher)

          # Send initial application name
          @writer.puts(matcher.current_app || "NOT FOUND")

          # Start DBus main loop
          loop = DBus::Main.new
          loop << bus
          loop.run
        rescue DBus::Error => e
          MultiLogger.error "DBus::Error: #{e.message}"
          MultiLogger.error "Have you installed KWin script?"
          MultiLogger.error "$ fusuma-appmatcher --install-kde-script"
          MultiLogger.error "Then restart your KDE session"
          exit 1
        end

        # DBus service that receives notifications from KWin script
        class Matcher < DBus::Object
          attr_reader :current_app

          def initialize(writer)
            super("/dev/iberianpig/Appmatcher/KDE")
            @writer = writer
            @current_app = nil
          end

          dbus_interface "dev.iberianpig.Appmatcher.KDE" do
            dbus_method :NotifyActiveWindow, "in caption:s, in resource_class:s, in resource_name:s" do |caption, resource_class, resource_name|
              # Use resourceClass as the application name (same as xremap)
              # Fallback to resourceName if resourceClass is empty
              app_name = if resource_class && !resource_class.empty?
                resource_class
              elsif resource_name && !resource_name.empty?
                resource_name
              else
                "NOT FOUND"
              end

              @current_app = app_name
              notify(app_name)
            end
          end

          private

          def notify(name)
            @writer.puts(name)
          rescue Errno::EPIPE
            exit 0
          rescue => e
            MultiLogger.error e.message
            exit 1
          end
        end
      end
    end
  end
end
