# frozen_string_literal: true

require "json"
require "dbus"
require_relative "./user_switcher"

module Fusuma
  module Plugin
    module Appmatcher
      # Search Active Window's Name
      class Gnome
        attr_reader :matcher, :reader, :writer

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

        def register_on_application_changed(matcher)
          matcher.on_active_application_changed do |name|
            notify(name)
          end
        end

        def notify(name)
          @writer.puts(name)
        rescue Errno::EPIPE
          exit 0
        rescue => e
          MultiLogger.error e.message
          exit 1
        end

        # Look up application name using dbus
        class Matcher
          def initialize
            session_bus = DBus.session_bus
            service = session_bus.service("org.gnome.Shell")
            @interface = service["/org/gnome/Shell"]["org.gnome.Shell"]
          rescue DBus::Error => e
            MultiLogger.error "DBus::Error: #{e.message}"

            exit 1
          end

          # @return [Array<Application>]
          def running_applications
            gnome_shell_eval(
              <<~GJS
                global.get_window_actors().map(a => a.get_meta_window().get_wm_class());
              GJS
            )
          end

          def active_application
            # const index = global.get_window_actors()
            #                   .findIndex(a=>a.meta_window.has_focus()===true);
            # global.get_window_actors()[index].get_meta_window().get_wm_class();
            gnome_shell_eval(
              <<~GJS
                const actor = global.get_window_actors().find(a=>a.meta_window.has_focus()===true)
                actor && actor.get_meta_window().get_wm_class()
              GJS
            )
          end

          # TODO
          # def window_title
          # # const index = global.get_window_actors()
          # #                   .findIndex(a=>a.meta_window.has_focus()===true);
          # # global.get_window_actors()[index].get_meta_window().get_title();
          #   gnome_shell_eval(
          #     # <<~GJS
          #     #   global.get_window_actors().map((current) => {
          #     #     const wm_class = current.get_meta_window().get_wm_class();
          #     #     const title = current.get_meta_window().get_title();
          #     #     return { application: wm_class, window_title: title }
          #     #   })
          #     # GJS
          #   )
          # end

          def gnome_shell_eval(string)
            success, body = @interface.Eval(string)

            if success
              response = begin
                JSON.parse(body)
              rescue
                nil
              end
              return response
            end

            raise body
          end

          def on_active_application_changed
            loop do
              sleep 0.5
              new_application = active_application
              next if @old_application == new_application

              yield(new_application || "NOT FOUND") if block_given?
              @old_application = new_application
            end
          end
        end
      end
    end
  end
end
