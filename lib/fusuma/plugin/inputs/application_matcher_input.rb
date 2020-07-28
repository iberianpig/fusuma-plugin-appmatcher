# frozen_string_literal: true

require_relative '../application_matcher/bamf.rb'

module Fusuma
  module Plugin
    module Inputs
      # Get active application's name
      class ApplicationMatcherInput < Input
        def run
          @check_time ||= Time.now
          return unless @check_time < Time.now

          @check_time = Time.now + 0.5
          event(record: application_name)
        end

        def application_name
          @bamf ||= Bamf.new
          @bamf.active_application_name || 'NOT_FOUND'
        end
      end
    end
  end
end
