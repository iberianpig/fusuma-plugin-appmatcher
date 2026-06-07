# frozen_string_literal: true

require "spec_helper"
require "fusuma/plugin/appmatcher/cosmic"

module Fusuma
  module Plugin
    module Appmatcher
      RSpec.describe Cosmic do
        describe ".available?" do
          context "when cos-cli is found in PATH" do
            before do
              status = instance_double(Process::Status, success?: true)
              allow(Open3).to receive(:capture3).with("which", "cos-cli")
                .and_return(["/usr/local/bin/cos-cli\n", "", status])
            end

            it "returns true" do
              expect(described_class.available?).to be true
            end
          end

          context "when which returns non-zero" do
            before do
              status = instance_double(Process::Status, success?: false)
              allow(Open3).to receive(:capture3).with("which", "cos-cli")
                .and_return(["", "", status])
            end

            it "returns false" do
              expect(described_class.available?).to be false
            end
          end

          context "when which command itself is missing" do
            before do
              allow(Open3).to receive(:capture3).with("which", "cos-cli")
                .and_raise(Errno::ENOENT)
            end

            it "returns false" do
              expect(described_class.available?).to be false
            end
          end
        end

        describe "#initialize" do
          let(:cosmic) { described_class.new }

          it "creates IO pipe for reader" do
            expect(cosmic.reader).to be_a(IO)
          end

          it "creates IO pipe for writer" do
            expect(cosmic.writer).to be_a(IO)
          end
        end
      end
    end
  end
end
