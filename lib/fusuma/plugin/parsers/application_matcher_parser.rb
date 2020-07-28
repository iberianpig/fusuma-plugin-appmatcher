# frozen_string_literal: true

module Fusuma
  module Plugin
    module Parsers
      # Generate ApplicationMatcherRecord from libinput_command_input
      class ApplicationMatcherParser < Parser
        DEFAULT_SOURCE = 'application_matcher_input'

        # @param record [String]
        # @return [Records::Gesture, nil]
        def parse_record(record)
          line = record.to_s
          Events::Records::ApplicationMatcherRecord.new(name: line)
        end
      end
    end
  end
end
