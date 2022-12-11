# frozen_string_literal: true

require "json"
require "dbus"
require_relative "./user_switcher"

module Fusuma
  module Plugin
    module Appmatcher
      # Search Active Window's Name
      class GnomeExtension
        attr_reader :reader, :writer

        def initialize
          @reader, @writer = IO.pipe
        end

        # fork process and watch signal
        # @return [Integer] Process id
        def watch_start
          @watch_start ||= begin
            pid = UserSwitcher.new.as_user(proctitle: self.class.name.underscore) do |user|
              @reader.close
              ENV["DBUS_SESSION_BUS_ADDRESS"] = "unix:path=/run/user/#{user.uid}/bus"
              register_on_application_changed(Matcher.new)
            end
            Process.detach(pid)
            pid
          end
        end

        private

        # @param matcher [Matcher]
        def register_on_application_changed(matcher)
          # NOTE: push current application to pipe before start
          @writer.puts(matcher.active_application)

          matcher.on_active_application_changed do |name|
            notify(name)
          end

          execute_loop(matcher)
        end

        def notify(name)
          @writer.puts(name)
        rescue Errno::EPIPE
          exit 0
        rescue => e
          MultiLogger.error e.message
          exit 1
        end

        def execute_loop(matcher)
          loop = DBus::Main.new
          loop << matcher.session_bus
          loop.run
        end

        # Look up application name using dbus
        class Matcher
          attr_reader :session_bus

          def initialize
            @session_bus = DBus.session_bus
            service = session_bus.service("org.gnome.Shell")
            @interface = service["/dev/iberianpig/Appmatcher"]["dev.iberianpig.Appmatcher"]
          rescue DBus::Error => e
            MultiLogger.error "DBus::Error: #{e.message}"
            MultiLogger.error "Have you installed GNOME extension?"
            MultiLogger.error "$ fusuma-appmatcher --install-gnome-extension"
            MultiLogger.error "Then Restart your session"

            exit 1
          end

          # @return [Array<String>]
          def running_applications
            applications = JSON.parse(@interface.ListWindows, object_class: Application)
            applications.map(&:wm_class)
          rescue JSON::ParserError => e
            MultiLogger.error e.message
            nil
          end

          # @return [String]
          def active_application
            app = JSON.parse(@interface.ActiveWindow, object_class: Application)
            app&.wm_class
          rescue JSON::ParserError => e
            MultiLogger.error e.message
            nil
          end

          def on_active_application_changed
            @interface.on_signal("ActiveWindowChanged") do |json|
              # if app is is not found, fetch active_application_id
              app =
                begin
                  JSON.parse(json, object_class: Application)
                rescue JSON::ParserError => e
                  MultiLogger.error e.message
                  nil
                end

              yield(app&.wm_class || "NOT FOUND") if block_given?
            end
          end
        end

        # Focused Application
        class Application
          attr_reader :wm_class, :pid, :id, :title, :focus

          # to specify as object_class in JSON.parse
          def []=(key, value)
            instance_variable_set("@#{key}", value)
          end

          def inspect
            "wm_class: #{wm_class}, pid: #{pid}, id: #{id}, title: #{title}, focus: #{focus}"
          end
        end
      end
    end
  end
end
