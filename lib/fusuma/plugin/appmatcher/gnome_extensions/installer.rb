# frozen_string_literal: true

require_relative "../user_switcher"
require "fileutils"

module Fusuma
  module Plugin
    module Appmatcher
      module GnomeExtensions
        # Install Gnome Extension
        class Installer
          include UserSwitcher

          EXTENSION = "./appmatcher@iberianpig.dev"

          def install
            pid = as_user(proctitle: self.class.name.underscore) do |user|
              FileUtils.cp_r(source_path, user_extension_dir(user.username))
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

          private

          def user_extension_dir(username = login_username)
            File.expand_path("#{Dir.home(username)}/.local/share/gnome-shell/extensions/")
          end

          def install_path(username = login_username)
            File.expand_path("#{Dir.home(username)}/.local/share/gnome-shell/extensions/#{EXTENSION}")
          end

          def source_path
            File.expand_path(EXTENSION, __dir__)
          end

          def login_username
            UserSwitcher.login_user.username
          end
        end
      end
    end
  end
end
