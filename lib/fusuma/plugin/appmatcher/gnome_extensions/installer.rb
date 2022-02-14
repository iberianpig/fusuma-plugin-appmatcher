# frozen_string_literal: true

require_relative "../user_switcher"
require "fileutils"

module Fusuma
  module Plugin
    module Appmatcher
      module GnomeExtensions
        # Install Gnome Extension
        class Installer
          EXTENSION = "./appmatcher@iberianpig.dev"

          def install
            pid = UserSwitcher.new.as_user do |user|
              FileUtils.cp_r(source_path, user_extension_dir(user.username))
              puts "Installed Appmatcher Gnome Shell Extension to #{user_extension_dir(user.username)}"
              puts "Restart your session, then activate Appmatcher on gnome-extensions-app"
            end
            Process.waitpid(pid)
          end

          def uninstall
            puts "Appmatcher Gnome Shell Extension is not installed" unless installed?

            pid = UserSwitcher.new.as_user do |user|
              FileUtils.rm_r(install_path(user.username))
              puts "Uninstalled Appmatcher Gnome Shell Extension from #{install_path(user.username)}."
            end
            Process.waitpid(pid)
          end

          def installed?
            result = false
            pid = UserSwitcher.new.as_user do |user|
              result = File.exist?(install_path(user.username))
            end
            Process.waitpid(pid)
            result
          end

          private

          def user_extension_dir(username)
            File.expand_path("#{Dir.home(username)}/.local/share/gnome-shell/extensions/")
          end

          def install_path(username)
            File.expand_path("#{Dir.home(username)}/.local/share/gnome-shell/extensions/#{EXTENSION}")
          end

          def source_path
            File.expand_path(EXTENSION, __dir__)
          end
        end
      end
    end
  end
end
