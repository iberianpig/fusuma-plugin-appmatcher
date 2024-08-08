# frozen_string_literal: true

require_relative "../appmatcher"

module Fusuma
  module Plugin
    module Inputs
      # Get active application's name
      class AppmatcherInput < Input
        def io
          return @io if instance_variable_defined?(:@io)

          @backend = Appmatcher.backend_klass.new

          @backend.watch_start
          # NOTE: Closing the parent process's pipe
          @backend.writer.close

          @io = @backend.reader
        end

        def shutdown
          # CustomProcess#shutdown
          @backend.shutdown
        end

        # TODO: use read_from_io
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
