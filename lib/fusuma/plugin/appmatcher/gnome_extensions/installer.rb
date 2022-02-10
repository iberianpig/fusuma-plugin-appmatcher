# frozen_string_literal: true

require_relative "../user_switcher"
require "fileutils"

module Fusuma
  module Plugin
    module Appmatcher
      module GnomeExtensions
        class Installer
          EXTENSION = "./appmatcher@iberianpig.dev"

          def install
            pid = UserSwitcher.new.as_user do |_user|
              source = File.expand_path(EXTENSION, __dir__)
              user_extension_dir = File.expand_path("#{Dir.home}/.local/share/gnome-shell/extensions/")

              FileUtils.cp_r(source, user_extension_dir)
              puts "Installed Appmatcher Gnome Shell Extension to #{user_extension_dir}"
              puts "Restart your session, then activate Appmatcher on gnome-extensions-app"
            end
            Process.waitpid(pid)
          end

          def uninstall
            pid = UserSwitcher.new.as_user do |_user|
              installed = File.expand_path("#{Dir.home}/.local/share/gnome-shell/extensions/#{EXTENSION}")

              FileUtils.rm_r(installed)
              puts "Uninstalled Appmatcher Gnome Shell Extension from #{installed}."
            end
            Process.waitpid(pid)
          end
        end
      end
    end
  end
end
