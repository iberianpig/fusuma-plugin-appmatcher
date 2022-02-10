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
            pid = UserSwitcher.new.as_user do |_user|
              FileUtils.cp_r(source_path, user_extension_dir)
              puts "Installed Appmatcher Gnome Shell Extension to #{user_extension_dir}"
              puts "Restart your session, then activate Appmatcher on gnome-extensions-app"
            end
            Process.waitpid(pid)
          end

          def installed?
            File.exist?(install_path)
          end

          def uninstall
            pid = UserSwitcher.new.as_user do |_user|
              if installed?
                FileUtils.rm_r(install_path)
                puts "Uninstalled Appmatcher Gnome Shell Extension from #{install_path}."
              else
                puts "Appmatcher Gnome Shell Extension is not installed"
              end
            end
            Process.waitpid(pid)
          end

          private

          def user_extension_dir
            File.expand_path("#{Dir.home}/.local/share/gnome-shell/extensions/")
          end

          def install_path
            File.expand_path("#{Dir.home}/.local/share/gnome-shell/extensions/#{EXTENSION}")
          end

          def source_path
            File.expand_path(EXTENSION, __dir__)
          end
        end
      end
    end
  end
end
