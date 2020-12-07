# frozen_string_literal: true

module Fusuma
  module Plugin
    module Detectors
      # Detect KeypressEvent from KeypressBuffer
      class AppmatcherDetector < Detector
        BUFFER_TYPE = 'appmatcher'

        DEFAULT_NAME = 'global'

        # @param buffers [Array<Event>]
        # @return [Event] if event is detected
        # @return [NilClass] if event is NOT detected
        def detect(buffers)
          buffer = buffers.find { |b| b.type == BUFFER_TYPE }

          return if buffer.empty?

          record = buffer.events.last.record

          index_record = Events::Records::IndexRecord.new(
            index: create_index(record: record),
            position: :prefix
          )

          create_event(record: index_record)
        end

        # @param record [Events::Records::KeypressRecord]
        # @return [Config::Index]
        def create_index(record:)
          Config::Index.new(
            [
              Config::Index::Key.new('application'),
              Config::Index::Key.new(record.name, fallback: DEFAULT_NAME)
            ]
          )
        end
      end
    end
  end
end
