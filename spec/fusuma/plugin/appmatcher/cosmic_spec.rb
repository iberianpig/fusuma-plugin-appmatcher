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

        describe Cosmic::Matcher do
          let(:matcher) { described_class.new }

          # Stub Open3.capture3 with a JSON output for `cos-cli info --json`
          def stub_info(stdout:, success: true)
            status = instance_double(Process::Status, success?: success)
            allow(Open3).to receive(:capture3).with("cos-cli", "info", "--json")
              .and_return([stdout, "", status])
          end

          describe "#active_application" do
            context "when an app has activated state" do
              before do
                stub_info(stdout: {
                  "apps" => [
                    {"app_id" => "firefox", "state" => []},
                    {"app_id" => "org.wezfurlong.wezterm", "state" => ["activated"]}
                  ]
                }.to_json)
              end

              it "returns the activated app_id" do
                expect(matcher.active_application).to eq("org.wezfurlong.wezterm")
              end
            end

            context "when no app is activated" do
              before do
                stub_info(stdout: {"apps" => [{"app_id" => "firefox", "state" => []}]}.to_json)
              end

              it "returns nil" do
                expect(matcher.active_application).to be_nil
              end
            end

            context "when cos-cli info exits non-zero" do
              before { stub_info(stdout: "", success: false) }

              it "returns nil" do
                expect(matcher.active_application).to be_nil
              end
            end

            context "when output is empty" do
              before { stub_info(stdout: "") }

              it "returns nil" do
                expect(matcher.active_application).to be_nil
              end
            end

            context "when JSON is invalid" do
              before { stub_info(stdout: "not json") }

              it "returns nil" do
                expect(matcher.active_application).to be_nil
              end
            end
          end
        end
      end
    end
  end
end
