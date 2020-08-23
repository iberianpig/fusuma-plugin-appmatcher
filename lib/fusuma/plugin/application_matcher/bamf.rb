# frozen_string_literal: true

require 'dbus'
require 'inifile'

module Fusuma
  module Plugin
    module ApplicationMatcher
      # Search Active Window's Name
      class Bamf
        attr_reader :matcher
        attr_reader :reader
        attr_reader :writer
        def initialize
          @session_bus = DBus.session_bus
          service = @session_bus.service('org.ayatana.bamf')
          @matcher = service['/org/ayatana/bamf/matcher']['org.ayatana.bamf.matcher']
          @reader, @writer = IO.pipe
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

        def fetch_applications
          @matcher.RunningApplicationsDesktopFiles.map do |file|
            {
              desktop_file: file,
              application_id: @matcher.PathForApplication(file)
            }
          end
        end

        def active_application_name
          app = active_application
          return if app.nil?

          desktop_file = app[:desktop_file]
          find_name(desktop_file)
        end

        def active_application(active_application_id = fetch_active_application_id)
          @activated ||= []
          @activated.find { |app| app[:application_id] == active_application_id } ||
            fetch_applications.find { |app| app[:application_id] == active_application_id }.tap do |active|
              @activated << active
              @activated.compact!
            end
        end

        def fetch_active_application_id
          @matcher.ActiveApplication
        end

        # fork process and watch signal
        # @return [Integer] Process id
        def watch_start
          @watch_start ||= begin
                     pid = fork do
                       @reader.close
                       loop = DBus::Main.new
                       loop << @session_bus
                       loop.run
                     end
                     Process.detach(pid)
                     pid
                   end
        end

        def on_active_application_changed
          @matcher.on_signal('ActiveApplicationChanged') do |_old, new_id|
            application = active_application(new_id)
            next if application.nil?

            begin
              io_write(find_name(application[:desktop_file]))
            rescue Errno::EPIPE
              exit 0
            rescue StandardError => e
              MultiLogger.error e.message
              exit 1
            end
          end
        end

        def io_write(content)
          @writer.puts(content)
        end

        def find_name(desktop_file)
          @names ||= {}

          @names[desktop_file] ||= begin
                                     ini = IniFile.load(desktop_file)
                                     ini['Desktop Entry']['Name']
                                   end
        end
      end
    end
  end
end
