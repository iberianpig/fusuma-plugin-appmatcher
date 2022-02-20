# frozen_string_literal: true

require "spec_helper"

require "fusuma/plugin/detectors/detector"
require "fusuma/plugin/buffers/buffer"

require "./lib/fusuma/plugin/buffers/appmatcher_buffer"
require "./lib/fusuma/plugin/detectors/appmatcher_detector"

module Fusuma
  module Plugin
    module Detectors
      RSpec.describe AppmatcherDetector do
        before do
          @detector = AppmatcherDetector.new
          @buffer = Buffers::AppmatcherBuffer.new
        end

        describe "#detector" do
          context "with no appmatcher event in buffer" do
            before do
              @buffer.clear
            end

            it { expect(@detector.detect([@buffer])).to eq nil }
          end
        end

        context "with appmatcher events in buffer" do
          before do
            record = Events::Records::AppmatcherRecord.new(name: "dummy")
            event = Events::Event.new(tag: "appmatcher_parser", record: record)

            @buffer.buffer(event)
          end
          it { expect(@detector.detect([@buffer])).to be_a Events::Event }
          it "should detect ContextRecord" do
            expect(@detector.detect([@buffer]).record).to be_a Events::Records::ContextRecord
          end
          it "should detect context: { application: dummy }" do
            record = @detector.detect([@buffer]).record
            expect(record.name).to eq :application
            expect(record.value).to eq "dummy"
          end
        end

        context "with two different appmatcher events in buffer" do
          before do
            record1 = Events::Records::AppmatcherRecord.new(name: "dummy1")
            record2 = Events::Records::AppmatcherRecord.new(name: "dummy2")
            event1 = Events::Event.new(tag: "appmatcher_parser", record: record1)
            event2 = Events::Event.new(tag: "appmatcher_parser", record: record2)

            @buffer.buffer(event1)
            @buffer.buffer(event2)
          end

          it "should detect latest application" do
            record = @detector.detect([@buffer]).record
            expect(record.name).to eq :application
            expect(record.value).to eq "dummy2"
          end
        end
      end
    end
  end
end
