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
            event = Events::Event.new(tag: "appmatcher_input", record: record)

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
            event1 = Events::Event.new(tag: "appmatcher_input", record: record1)
            event2 = Events::Event.new(tag: "appmatcher_input", record: record2)

            @buffer.buffer(event1)
            @buffer.buffer(event2)
          end

          it "should detect latest application" do
            record = @detector.detect([@buffer]).record
            expect(record.name).to eq :application
            expect(record.value).to eq "dummy2"
          end
        end

        describe "#layer_manager_available?" do
          before do
            # Reset cache before each test
            if @detector.instance_variable_defined?(:@layer_manager_available)
              @detector.remove_instance_variable(:@layer_manager_available)
            end
          end

          context "when fusuma-plugin-remap is installed" do
            before do
              remap_input_class = double("RemapKeyboardInput", name: "Fusuma::Plugin::Inputs::RemapKeyboardInput")

              allow(Plugin::Manager).to receive(:plugins).and_return({
                Inputs::Input.name => [remap_input_class]
              })
            end

            it "returns true" do
              expect(@detector.send(:layer_manager_available?)).to be true
            end
          end

          context "when fusuma-plugin-remap is NOT installed" do
            before do
              allow(Plugin::Manager).to receive(:plugins).and_return({
                Inputs::Input.name => []
              })
            end

            it "returns false" do
              expect(@detector.send(:layer_manager_available?)).to be false
            end
          end

          # Verify that the result is cached
          context "called multiple times" do
            it "returns cached result" do
              allow(Plugin::Manager).to receive(:plugins).and_return({Inputs::Input.name => []})

              result1 = @detector.send(:layer_manager_available?)
              result2 = @detector.send(:layer_manager_available?)

              expect(result1).to eq result2
              expect(Plugin::Manager).to have_received(:plugins).once
            end
          end
        end

        describe "#update_layer" do
          let(:layer_manager) { double("LayerManager") }

          before do
            if @detector.instance_variable_defined?(:@layer_manager_available)
              @detector.remove_instance_variable(:@layer_manager_available)
            end
            if @detector.instance_variable_defined?(:@previous_app)
              @detector.remove_instance_variable(:@previous_app)
            end

            allow(@detector).to receive(:layer_manager).and_return(layer_manager)
            allow(layer_manager).to receive(:send_layer)
          end

          context "when detecting the app for the first time" do
            it "adds current app layer" do
              @detector.send(:update_layer, "google-chrome")

              expect(layer_manager).to have_received(:send_layer).with(
                layer: {application: "google-chrome"}
              )
            end

            it "does not attempt to remove previous app layer" do
              @detector.send(:update_layer, "google-chrome")

              expect(layer_manager).not_to have_received(:send_layer).with(
                hash_including(remove: true)
              )
            end
          end

          context "when changing to a different app" do
            before do
              @detector.send(:update_layer, "google-chrome")
              allow(layer_manager).to receive(:send_layer)
            end

            it "deletes the previous app's layer" do
              @detector.send(:update_layer, "code")

              expect(layer_manager).to have_received(:send_layer).with(
                layer: {application: "google-chrome"},
                remove: true
              )
            end

            it "adds the current app's layer" do
              @detector.send(:update_layer, "code")

              expect(layer_manager).to have_received(:send_layer).with(
                layer: {application: "code"}
              )
            end
          end

          # Case of the same app: do nothing (to prevent duplicate sending)
          context "with the same app as before" do
            before do
              @detector.instance_variable_set(:@previous_app, "google-chrome")
            end

            it "does not remove previous app layer" do
              @detector.send(:update_layer, "google-chrome")

              expect(layer_manager).not_to have_received(:send_layer)
            end
          end
        end
      end
    end
  end
end
