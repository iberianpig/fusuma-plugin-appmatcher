# frozen_string_literal: true

require_relative "../user_switcher"
require "fileutils"
require "yaml"

module Fusuma
  module Plugin
    module Appmatcher
      module GnomeExtensions
        # Install Gnome Extension
        class Installer
          include UserSwitcher

          def install
            pid = as_user(proctitle: self.class.name.underscore) do |user|
              FileUtils.cp_r(source_path, install_path(user.username))
              puts "Installed Appmatcher Gnome Shell Extension to #{user_extension_dir(user.username)}"
              puts "Restart your session, then activate Appmatcher on gnome-extensions-app"
            end
            Process.waitpid(pid)
          end

          def uninstall
            return puts "Appmatcher Gnome Shell Extension is not installed in #{user_extension_dir}/" unless installed?

            pid = as_user(proctitle: self.class.name.underscore) do |user|
              FileUtils.rm_r(install_path(user.username))
              puts "Uninstalled Appmatcher Gnome Shell Extension from #{install_path(user.username)}"
            end
            Process.waitpid(pid)
          end

          def installed?
            File.exist?(install_path)
          end

          def enabled?
            enabled_extensions = YAML.load(`gsettings get org.gnome.shell enabled-extensions`)
            enabled_extensions&.include?(EXTENSION)
          end

          private

          def user_extension_dir(username = login_username)
            File.expand_path("#{Dir.home(username)}/.local/share/gnome-shell/extensions/")
          end

          EXTENSION = "appmatcher@iberianpig.dev"
          EXTENSION45 = "appmatcher45@iberianpig.dev"
          def install_path(username = login_username)
            File.expand_path("#{Dir.home(username)}/.local/share/gnome-shell/extensions/#{EXTENSION}")
          end

          def source_path
            File.expand_path(gnome_shell_extension_filename, __dir__)
          end

          def gnome_shell_extension_filename
            output = `gnome-shell --version`
            version = output.match(/GNOME Shell (\d+\.\d+)/)

            if version
              version_number = version[1].to_f
              if version_number >= 45.0
                EXTENSION45
              else
                EXTENSION
              end
            else
              EXTENSION
            end
          end

          def login_username
            UserSwitcher.login_user.username
          end
        end
      end
    end
  end
end
