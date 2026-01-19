# frozen_string_literal: true

module Fusuma
  module Plugin
    module Detectors
      # Detect KeypressEvent from KeypressBuffer
      class AppmatcherDetector < Detector
        SOURCES = ["appmatcher"].freeze
        BUFFER_TYPE = "appmatcher"

        # Always watch buffers and detect them.
        def watch?
          true
        end

        # @param buffers [Array<Event>]
        # @return [Event] if event is detected
        # @return [NilClass] if event is NOT detected
        def detect(buffers)
          buffer = buffers.find { |b| b.type == BUFFER_TYPE }

          return if buffer.empty?

          record = buffer.events.last.record

          update_layer(record.name) if layer_manager_available?

          context_record = Events::Records::ContextRecord.new(
            name: "application",
            value: record.name
          )

          create_event(record: context_record)
        end

        private

        # Check fusuma-plugin-remap is installed for layer management
        def layer_manager_available?
          return @layer_manager_available if defined?(@layer_manager_available)

          @layer_manager_available = Plugin::Manager.plugins[Inputs::Input.name]&.any? { |klass|
            klass.name == "Fusuma::Plugin::Inputs::RemapKeyboardInput"
          } || false
        end

        def layer_manager
          require "fusuma/plugin/remap/layer_manager"
          Fusuma::Plugin::Remap::LayerManager.instance
        end

        # Update layer on application change
        # - On first detection: add current app as layer
        # - On app change: remove previous layer and add new layer
        # - On same app: do nothing
        def update_layer(current_app)
          return if @previous_app == current_app

          if @previous_app
            layer_manager.send_layer(layer: {application: @previous_app}, remove: true)
          end

          layer_manager.send_layer(layer: {application: current_app})

          @previous_app = current_app
        end
      end
    end
  end
end
