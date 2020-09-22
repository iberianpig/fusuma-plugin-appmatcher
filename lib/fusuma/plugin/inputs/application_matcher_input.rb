# frozen_string_literal: true

require_relative '../application_matcher/bamf.rb'

module Fusuma
  module Plugin
    module Inputs
      # Get active application's name
      class ApplicationMatcherInput < Input
        def io
          @bamf ||= Fusuma::Plugin::ApplicationMatcher::Bamf.new

          @pid ||= begin
                     pid = @bamf.watch_start
                     # NOTE: Closing the parent process's pipe
                     @bamf.writer.close

                     pid
                   end

          @bamf.reader
        end
      end
    end
  end
end
