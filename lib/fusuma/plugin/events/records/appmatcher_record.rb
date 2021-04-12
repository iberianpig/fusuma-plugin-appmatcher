# frozen_string_literal: true

module Fusuma
  module Plugin
    module Events
      module Records
        # Record for Keypress event
        class AppmatcherRecord < Record
          attr_reader :name

          # @param status [String]
          def initialize(name:)
            super()
            @name = name
          end
        end
      end
    end
  end
end
