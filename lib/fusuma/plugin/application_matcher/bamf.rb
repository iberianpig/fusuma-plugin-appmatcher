# frozen_string_literal: true

require 'dbus'
require 'iniparse'
require_relative './user_switcher.rb'

module Fusuma
  module Plugin
    module ApplicationMatcher
      # Search Active Window's Name
      class Bamf
        attr_reader :matcher
        attr_reader :reader
        attr_reader :writer
        def initialize
          @reader, @writer = IO.pipe
        end

        # fork process and watch signal
        # @return [Integer] Process id
        def watch_start
          @watch_start ||= begin
                     pid = UserSwitcher.new.as_user do |user|
                       @reader.close
                       ENV['DBUS_SESSION_BUS_ADDRESS'] = "unix:path=/run/user/#{user.uid}/bus"
                       session_bus = DBus.session_bus

                       register_on_application_changed(Matcher.new(session_bus))
                       execute_loop(session_bus)
                     end
                     Process.detach(pid)
                     pid
                   end
        end

        private

        def execute_loop(session_bus)
          loop = DBus::Main.new
          loop << session_bus
          loop.run
        end

        def register_on_application_changed(matcher)
          # NOTE: push current application to pipe before start
          notify(matcher.active_application&.name)

          matcher.on_active_application_changed do |name|
            notify(name)
          end
        end

        def notify(name)
          @writer.puts(name)
        rescue Errno::EPIPE
          exit 0
        rescue StandardError => e
          MultiLogger.error e.message
          exit 1
        end

        # interface.methods.keys
        # => ["XidsForApplication",
        #  "TabPaths",
        #  "RunningApplications",
        #  "RunningApplicationsDesktopFiles",
        #  "RegisterFavorites",
        #  "PathForApplication",
        #  "WindowPaths",
        #  "ApplicationPaths",
        #  "ApplicationIsRunning",
        #  "ApplicationForXid",
        #  "ActiveWindow",
        #  "ActiveApplication",
        #  "WindowStackForMonitor"]

        #   <interface name="org.ayatana.bamf.matcher">
        #     <method name="XidsForApplication">
        #       <arg type="s" name="desktop_file" direction="in"/>
        #       <arg type="au" name="xids" direction="out"/>
        #     </method>
        #     <method name="TabPaths">
        #       <arg type="as" name="paths" direction="out"/>
        #     </method>
        #     <method name="RunningApplications">
        #       <arg type="as" name="paths" direction="out"/>
        #     </method>
        #     <method name="RunningApplicationsDesktopFiles">
        #       <arg type="as" name="paths" direction="out"/>
        #     </method>
        #     <method name="RegisterFavorites">
        #       <arg type="as" name="favorites" direction="in"/>
        #     </method>
        #     <method name="PathForApplication">
        #       <arg type="s" name="desktop_file" direction="in"/>
        #       <arg type="s" name="path" direction="out"/>
        #     </method>
        #     <method name="WindowPaths">
        #       <arg type="as" name="paths" direction="out"/>
        #     </method>
        #     <method name="ApplicationPaths">
        #       <arg type="as" name="paths" direction="out"/>
        #     </method>
        #     <method name="ApplicationIsRunning">
        #       <arg type="s" name="desktop_file" direction="in"/>
        #       <arg type="b" name="running" direction="out"/>
        #     </method>
        #     <method name="ApplicationForXid">
        #       <arg type="u" name="xid" direction="in"/>
        #       <arg type="s" name="application" direction="out"/>
        #     </method>
        #     <method name="ActiveWindow">
        #       <arg type="s" name="window" direction="out"/>
        #     </method>
        #     <method name="ActiveApplication">
        #       <arg type="s" name="application" direction="out"/>
        #     </method>
        #     <method name="WindowStackForMonitor">
        #       <arg type="i" name="monitor_id" direction="in"/>
        #       <arg type="as" name="window_list" direction="out"/>
        #     </method>
        #     <signal name="ActiveApplicationChanged">
        #       <arg type="s" name="old_app"/>
        #       <arg type="s" name="new_app"/>
        #     </signal>
        #     <signal name="ActiveWindowChanged">
        #       <arg type="s" name="old_win"/>
        #       <arg type="s" name="new_win"/>
        #     </signal>
        #     <signal name="ViewClosed">
        #       <arg type="s" name="path"/>
        #       <arg type="s" name="type"/>
        #     </signal>
        #     <signal name="ViewOpened">
        #       <arg type="s" name="path"/>
        #       <arg type="s" name="type"/>
        #     </signal>
        #     <signal name="StackingOrderChanged"/>
        #     <signal name="RunningApplicationsChanged">
        #       <arg type="as" name="opened_desktop_files"/>
        #       <arg type="as" name="closed_desktop_files"/>
        #     </signal>
        #   </interface>
        # </node>
        class Matcher
          def initialize(session_bus)
            service = session_bus.service('org.ayatana.bamf')
            @interface = service['/org/ayatana/bamf/matcher']['org.ayatana.bamf.matcher']
          rescue DBus::Error => e
            MultiLogger.error "DBus::Error: #{e.message}"
            MultiLogger.error 'Have you installed bamfdaemon?'

            exit 1
          end

          # @return [Array<Application>]
          def running_applications
            @interface.RunningApplicationsDesktopFiles.map do |desktop_file|
              Application.new(
                desktop_file: desktop_file,
                id: @interface.PathForApplication(desktop_file)
              )
            end
          end

          # @return [Application]
          def active_application(id = active_application_id)
            @cached ||= []

            @cached.find do |app|
              app.id == id
            end || running_applications.find do |app|
              # cache applications
              @cached << app
              @cached.compact!

              app.id == id
            end
          end

          def active_application_id
            @interface.ActiveApplication
          end

          def on_active_application_changed
            @interface.on_signal('ActiveApplicationChanged') do |_old, new_id|
              # if app is is not found, fetch active_application_id
              application = active_application(new_id) || active_application
              yield(application&.name || 'NOT FOUND') if block_given?
            end
          end

          # identify Application
          class Application
            attr_reader :desktop_file, :id

            def initialize(desktop_file:, id:)
              @desktop_file = desktop_file
              @id = id
            end

            def name
              self.class.find_name(desktop_file)
            end

            def self.find_name(desktop_file)
              @names ||= {}

              @names[desktop_file] ||= find_wm_class(desktop_file) || basename(desktop_file)
            end

            def self.find_wm_class(desktop_file)
              ini = IniParse.parse(File.read(desktop_file))
              ini['Desktop Entry']['StartupWMClass']
            end

            def self.basename(desktop_file)
              File.basename(desktop_file).chomp('.desktop')
            end
          end
        end
      end
    end
  end
end
