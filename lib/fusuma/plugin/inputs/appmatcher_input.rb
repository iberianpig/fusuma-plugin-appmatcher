# frozen_string_literal: true

require_relative '../appmatcher.rb'

module Fusuma
  module Plugin
    module Inputs
      # Get active application's name
      class AppmatcherInput < Input
        attr_reader :pid

        def io
          @backend ||= Appmatcher.backend_klass.new

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
