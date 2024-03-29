# frozen_string_literal: true

module Fusuma
  module Plugin
    module Buffers
      # Buffer events having KeypressRecord
      class AppmatcherBuffer < Buffer
        DEFAULT_SOURCE = "appmatcher_input"

        # @param event [Event]
        def buffer(event)
          return if event&.tag != source

          @events.push(event)
        end

        def clear_expired(*)
          @events = [@events.last] if @events.size > 100
        end

        def empty?
          @events.empty?
        end
      end
    end
  end
end
