# frozen_string_literal: true

module Fusuma
  module Plugin
    module Parsers
      # Generate AppmatcherRecord from libinput_command_input
      class AppmatcherParser < Parser
        DEFAULT_SOURCE = "appmatcher_input"

        # @param record [String]
        # @return [Records::Gesture, nil]
        def parse_record(record)
          line = record.to_s
          Events::Records::AppmatcherRecord.new(name: line)
        end
      end
    end
  end
end
