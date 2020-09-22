# frozen_string_literal: true

module Fusuma
  module Plugin
    module ApplicationMatcher
      class UserSwitcher
        User = Struct.new(:username, :uid, :gid)
        def initialize
          username = `logname`.chomp
          uid = `id -u #{username}`.chomp.to_i
          gid = `id -g #{username}`.chomp.to_i
          @login_user = User.new(username, uid, gid)
        end

        # Drops privileges to that of the specified user
        def drop_priv(user)
          # Process.initgroups(user.username, user.gid)
          Process::Sys.setegid(user.gid)
          Process::Sys.setgid(user.gid)
          Process::Sys.setuid(user.uid)
        end

        # Execute the provided block in a child process as the specified user
        # The parent blocks until the child finishes.
        def as_user(user = @login_user)
          fork do
            drop_priv(user)
            yield(user) if block_given?
          end
        end
      end
    end
  end
end
