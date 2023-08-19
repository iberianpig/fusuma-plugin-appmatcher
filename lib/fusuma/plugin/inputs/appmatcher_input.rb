# frozen_string_literal: true

require_relative "../appmatcher"

module Fusuma
  module Plugin
    module Inputs
      # Get active application's name
      class AppmatcherInput < Input
        attr_reader :pid

        def io
          @backend ||= Appmatcher.backend_klass.new

          @pid ||= begin
            pid = @backend.watch_start
            # NOTE: Closing the parent process's pipe
            @backend.writer.close

            pid
          end

          @backend.reader
        end

        def shutdown
          # CustomProcess#shutdown
          @backend.shutdown
        end

        # @param record [String] application name
        # @return [Event]
        def create_event(record:)
          e = Events::Event.new(
            tag: tag,
            record: Events::Records::AppmatcherRecord.new(name: record)
          )
          MultiLogger.debug(input_event: e)
          e
        end
      end
    end
  end
end
