# frozen_string_literal: true

require "dbus"
require_relative "../user_switcher"
require "fileutils"
require "fusuma/multi_logger"

module Fusuma
  module Plugin
    module Appmatcher
      module KwinScripts
        # Install KWin Script for KDE Wayland
        class Installer
          include UserSwitcher

          SCRIPT_NAME = "appmatcher-kde"

          def install
            pid = as_user(proctitle: self.class.name.underscore) do |user|
              FileUtils.mkdir_p(user_script_dir(user.username))
              FileUtils.cp_r(source_path, install_path(user.username))
              puts "Installed Appmatcher KWin Script to #{install_path(user.username)}"

              # Load and run the script via DBus
              load_and_run_script(user)

              puts "Restart your KDE session or re-login to ensure the script is active"
            end
            Process.waitpid(pid)
          end

          def uninstall
            return puts "Appmatcher KWin Script is not installed in #{install_path}/" unless installed?

            pid = as_user(proctitle: self.class.name.underscore) do |user|
              # Unload script via DBus
              unload_script(user)

              FileUtils.rm_r(install_path(user.username))
              puts "Uninstalled Appmatcher KWin Script from #{install_path(user.username)}"
            end
            Process.waitpid(pid)
          end

          def installed?
            File.exist?(install_path)
          end

          def enabled?
            return false unless installed?

            # Check if the script is loaded via DBus
            script_loaded?
          rescue DBus::Error => e
            MultiLogger.debug "DBus error while checking if script is loaded: #{e.message}"
            false
          end

          private

          def user_script_dir(username = login_username)
            File.expand_path("#{Dir.home(username)}/.local/share/kwin/scripts/")
          end

          def install_path(username = login_username)
            File.join(user_script_dir(username), SCRIPT_NAME)
          end

          def source_path
            File.expand_path(SCRIPT_NAME, __dir__)
          end

          def login_username
            UserSwitcher.login_user.username
          end

          def load_and_run_script(user)
            ENV["DBUS_SESSION_BUS_ADDRESS"] = "unix:path=/run/user/#{user.uid}/bus"
            bus = DBus.session_bus
            kwin_service = bus.service("org.kde.KWin")
            kwin_scripting = kwin_service.object("/Scripting")
            kwin_scripting.introspect
            kwin_scripting.default_iface = "org.kde.kwin.Scripting"

            # Check if script is already loaded
            return if kwin_scripting.isScriptLoaded(SCRIPT_NAME)[0]

            # Load the script
            script_path = install_path(user.username)
            script_obj_path = kwin_scripting.loadScript(script_path, SCRIPT_NAME)[0]

            # Get the script object and start it
            script_obj = kwin_service.object(script_obj_path)
            script_obj.introspect
            script_obj.default_iface = "org.kde.kwin.Script"
            script_obj.run

            puts "KWin script loaded and started successfully"
          rescue DBus::Error => e
            MultiLogger.error "Failed to load KWin script via DBus: #{e.message}"
            MultiLogger.error "Please restart your KDE session to activate the script"
          end

          def unload_script(user)
            ENV["DBUS_SESSION_BUS_ADDRESS"] = "unix:path=/run/user/#{user.uid}/bus"
            bus = DBus.session_bus
            kwin_service = bus.service("org.kde.KWin")
            kwin_scripting = kwin_service.object("/Scripting")
            kwin_scripting.introspect
            kwin_scripting.default_iface = "org.kde.kwin.Scripting"

            kwin_scripting.unloadScript(SCRIPT_NAME) if kwin_scripting.isScriptLoaded(SCRIPT_NAME)[0]
          rescue DBus::Error => e
            MultiLogger.debug "DBus error while unloading script: #{e.message}"
          end

          def script_loaded?
            user = UserSwitcher.login_user
            ENV["DBUS_SESSION_BUS_ADDRESS"] = "unix:path=/run/user/#{user.uid}/bus"
            bus = DBus.session_bus
            kwin_service = bus.service("org.kde.KWin")
            kwin_scripting = kwin_service.object("/Scripting")
            kwin_scripting.introspect
            kwin_scripting.default_iface = "org.kde.kwin.Scripting"

            kwin_scripting.isScriptLoaded(SCRIPT_NAME)[0]
          end
        end
      end
    end
  end
end
