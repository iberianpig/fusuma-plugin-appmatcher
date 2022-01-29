# frozen_string_literal: true

module Fusuma
  module Plugin
    module Detectors
      # Detect KeypressEvent from KeypressBuffer
      class AppmatcherDetector < Detector
        SOURCES = ['appmatcher'].freeze
        BUFFER_TYPE = 'appmatcher'

        # Always watch buffers and detect them.
        def watch?
          true
        end

        # @param buffers [Array<Event>]
        # @return [Event] if event is detected
        # @return [NilClass] if event is NOT detected
        def detect(buffers)
          buffer = buffers.find { |b| b.type == BUFFER_TYPE }

          return if buffer.empty?

          record = buffer.events.last.record

          context_record = Events::Records::ContextRecord.new(
            name: 'application',
            value: record.name
          )

          create_event(record: context_record)
        end
      end
    end
  end
end
