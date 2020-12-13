# frozen_string_literal: true

require_relative './user_switcher.rb'
require 'posix/spawn'

module Fusuma
  module Plugin
    module Appmatcher
      # Search Active Window's Name
      class X11
        attr_reader :matcher
        attr_reader :reader
        attr_reader :writer
        def initialize
          @reader, @writer = IO.pipe
        end

        # fork process and watch signal
        # @return [Integer] Process id
        def watch_start
          @watch_start ||= begin
                     pid = UserSwitcher.new.as_user do |_user|
                       @reader.close
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
        rescue StandardError => e
          MultiLogger.error e.message
          exit 1
        end

        # Look up  application name using xprop
        class Matcher
          # @return [Array<String>]
          def running_applications
            `xprop -root _NET_CLIENT_LIST_STACKING`.split(', ')
                                                   .map { |id_str| id_str.match(/0x[\da-z]{2,}/).to_s }
                                                   .map { |id| active_application(id) }
          end

          # @return [String]
          # @return [NilClass]
          def active_application(id = active_window_id)
            @cache ||= {}
            @cache[id] ||= begin
                             return if id.nil?

                             `xprop -id #{id} WM_CLASS | cut -d "=" -f 2 | tr -d '"'`.strip.split(', ').last
                           end
          end

          def on_active_application_changed
            active_window_id(watch: true) do |id|
              yield(active_application(id) || 'NOT FOUND')
            end
          end

          private

          def active_window_id(watch: false)
            _p, i, o, _e = POSIX::Spawn.popen4(xprop_active_window_id(watch))
            i.close
            o.each do |line|
              id = line.match(/0x[\da-z]{2,}/)&.to_s

              return id unless block_given?

              yield(id)
            end
          end

          # @param spy [TrueClass, FalseClass]
          # @return [String]
          def xprop_active_window_id(spy)
            spy_option = '-spy' if spy
            "xprop #{spy_option} -root _NET_ACTIVE_WINDOW"
          end
        end
      end
    end
  end
end
