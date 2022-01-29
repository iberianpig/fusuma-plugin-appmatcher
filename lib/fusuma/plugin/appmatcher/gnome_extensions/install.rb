# frozen_string_literal: true

require_relative "../user_switcher"
require "fileutils"

module Fusuma
  module Plugin
    module Appmatcher
      module GnomeExtensions
        class Installer
          def call
            pid = UserSwitcher.new.as_user do |_user|
              source_dir = File.expand_path("./appmatcher@iberianpig.dev", __dir__)
              user_extension_dir = File.expand_path("#{Dir.home}/.local/share/gnome-shell/extensions/")
              FileUtils.cp_r(source_dir, user_extension_dir)
            end
            Process.waitpid(pid)
          end
        end
      end
    end
  end
end
