# frozen_string_literal: true

require "fusuma/custom_process"
require "etc"

module Fusuma
  module Plugin
    module Appmatcher
      # Drop sudo privileges
      module UserSwitcher
        include CustomProcess

        # Drops privileges to that of the specified user
        def drop_priv(user)
          # Process.initgroups(user.username, user.gid)
          Process::Sys.setegid(user.gid)
          Process::Sys.setgid(user.gid)
          Process::Sys.setuid(user.uid)
        end

        # Execute the provided block in a child process as the specified user
        # The parent blocks until the child finishes.
        def as_user(user = login_user, proctitle:)
          self.proctitle = "#{self.class.name.underscore}(#{user.username}) -> #{proctitle}"

          fork do
            drop_priv(user)
            yield(user) if block_given?
          end
        end

        User = Struct.new(:username, :uid, :gid)
        def login_user
          @login_user ||= begin
            username = ENV["SUDO_USER"] || Etc.getlogin
            uid = `id -u #{username}`.chomp.to_i
            gid = `id -g #{username}`.chomp.to_i
            User.new(username, uid, gid)
          end
        end
        module_function :login_user
      end
    end
  end
end
