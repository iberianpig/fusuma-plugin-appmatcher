# frozen_string_literal: true

require "open3"
require_relative "user_switcher"
require "fusuma/multi_logger"
require "fusuma/custom_process"

module Fusuma
  module Plugin
    module Appmatcher
      # Search Active Window's Name
      class X11
        include UserSwitcher

        attr_reader :reader, :writer

        def initialize
          @reader, @writer = IO.pipe
        end

        # fork process and watch signal
        # @return [Integer] Process id
        def watch_start
          as_user(proctitle: self.class.name.underscore) do |_user|
            @reader.close
            register_on_application_changed(Matcher.new)
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
        rescue => e
          MultiLogger.error e.message
          exit 1
        end

        # Look up  application name using xprop
        class Matcher
          # @return [Array<String>]
          def running_applications
            `xprop -root _NET_CLIENT_LIST_STACKING`.split(", ")
              .map { |id_str| id_str.match(/0x[\da-z]{2,}/).to_s }
              .map { |id| active_application(id) }
          end

          # @return [String]
          # @return [NilClass]
          def active_application(id = active_window_id)
            @cache ||= {}
            @cache[id] ||= if id.nil?
              nil
            else
              `xprop -id #{id} WM_CLASS | cut -d "=" -f 2 | tr -d '"'`.strip.split(", ").last
            end
          end

          def on_active_application_changed
            active_window_id(watch: true) do |id|
              yield(active_application(id) || "NOT FOUND")
            end
          end

          private

          def active_window_id(watch: false, &block)
            i, o, e, _w = Open3.popen3(xprop_active_window_id(watch))
            i.close
            o.each do |line|
              id = line.match(/0x[\da-z]{2,}/)&.to_s

              return id unless block

              yield(id)
            end
            MultiLogger.error e.read if o.eof?
            e.close
            o.close

            return nil unless block

            sleep 0.5
            active_window_id(watch: watch, &block)
          rescue => e
            MultiLogger.error e.message
          end

          # @param spy [TrueClass, FalseClass]
          # @return [String]
          def xprop_active_window_id(spy)
            spy_option = "-spy" if spy
            "xprop #{spy_option} -root _NET_ACTIVE_WINDOW"
          end
        end
      end
    end
  end
end
