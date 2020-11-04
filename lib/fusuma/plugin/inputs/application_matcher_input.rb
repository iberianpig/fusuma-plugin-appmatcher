# frozen_string_literal: true

require_relative '../application_matcher/x11.rb'

module Fusuma
  module Plugin
    module Inputs
      # Get active application's name
      class ApplicationMatcherInput < Input
        def io
          @backend ||= Fusuma::Plugin::ApplicationMatcher::X11.new

          @pid ||= begin
                     pid = @backend.watch_start
                     # NOTE: Closing the parent process's pipe
                     @backend.writer.close

                     pid
                   end

          @backend.reader
        end
      end
    end
  end
end
