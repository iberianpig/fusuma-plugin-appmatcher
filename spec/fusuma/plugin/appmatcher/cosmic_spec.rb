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

          describe "#running_applications" do
            context "when apps are present" do
              before do
                stub_info(stdout: {
                  "apps" => [
                    {"app_id" => "firefox", "state" => []},
                    {"app_id" => "kitty", "state" => ["activated"]},
                    {"app_id" => "firefox", "state" => ["maximized"]}
                  ]
                }.to_json)
              end

              it "returns unique app_ids" do
                expect(matcher.running_applications).to contain_exactly("firefox", "kitty")
              end
            end

            context "when info fetch fails" do
              before { stub_info(stdout: "", success: false) }

              it "returns empty array" do
                expect(matcher.running_applications).to eq([])
              end
            end

            context "when apps array is missing" do
              before { stub_info(stdout: "{}") }

              it "returns empty array" do
                expect(matcher.running_applications).to eq([])
              end
            end
          end

          describe "#on_active_application_changed" do
            # Build a JSON-RPC state_change notification line
            def notification(app_id, state: ["activated"])
              {
                "jsonrpc" => "2.0",
                "method" => "state_change",
                "params" => {
                  "state" => {
                    "apps" => app_id ? [{"app_id" => app_id, "state" => state}] : []
                  }
                }
              }.to_json + "\n"
            end

            # Stub Open3.popen3 to feed the given lines as cos-cli serve stdout.
            def stub_serve(lines)
              stdout = StringIO.new(lines.join)
              stderr = StringIO.new("")
              stdin = StringIO.new
              wait_thr = double("wait_thr")
              allow(Open3).to receive(:popen3).with("cos-cli", "serve")
                .and_yield(stdin, stdout, stderr, wait_thr)
            end

            # When the stubbed stdout StringIO is exhausted, `subscribe_state_change`
            # returns normally (no exception). `on_active_application_changed` then
            # exits without entering its `rescue => e; sleep 1; retry` branch.
            # So happy-path tests just verify `yielded` content after normal return.

            it "yields activated app_id on state_change" do
              stub_serve([notification("firefox")])
              yielded = []
              matcher.on_active_application_changed { |name| yielded << name }
              expect(yielded).to eq(["firefox"])
            end

            it "ignores non state_change methods" do
              other = {"jsonrpc" => "2.0", "method" => "other", "params" => {}}.to_json + "\n"
              stub_serve([other, notification("kitty")])
              yielded = []
              matcher.on_active_application_changed { |name| yielded << name }
              expect(yielded).to eq(["kitty"])
            end

            it "skips consecutive duplicate app_ids" do
              stub_serve([
                notification("firefox"),
                notification("firefox"),
                notification("kitty")
              ])
              yielded = []
              matcher.on_active_application_changed { |name| yielded << name }
              expect(yielded).to eq(["firefox", "kitty"])
            end

            it "yields NOT FOUND once when no app is activated" do
              stub_serve([notification(nil), notification(nil)])
              yielded = []
              matcher.on_active_application_changed { |name| yielded << name }
              expect(yielded).to eq(["NOT FOUND"])
            end

            it "skips invalid JSON lines" do
              stub_serve(["not json\n", notification("kitty")])
              allow(Fusuma::MultiLogger).to receive(:warn)
              yielded = []
              matcher.on_active_application_changed { |name| yielded << name }
              expect(yielded).to eq(["kitty"])
              expect(Fusuma::MultiLogger).to have_received(:warn).with(/Failed to parse/)
            end

            # ENOENT path DOES exercise the rescue/retry branch in
            # on_active_application_changed (subscribe_state_change re-raises).
            # Use sleep stub to break out of the otherwise infinite retry loop.
            it "logs and retries when cos-cli serve is missing" do
              allow(Open3).to receive(:popen3).with("cos-cli", "serve")
                .and_raise(Errno::ENOENT)
              allow(Fusuma::MultiLogger).to receive(:error)
              # SystemExit is not caught by `rescue => e` (StandardError only),
              # so it propagates out of the retry loop.
              allow(matcher).to receive(:sleep).and_raise(SystemExit)

              expect {
                matcher.on_active_application_changed { |_| }
              }.to raise_error(SystemExit)

              expect(Fusuma::MultiLogger).to have_received(:error).with(/cos-cli command not found/)
            end
          end
        end

        describe "#notify and registration flow" do
          let(:cosmic) { described_class.new }

          it "writes initial active_application to writer" do
            matcher = instance_double(Cosmic::Matcher)
            allow(matcher).to receive(:active_application).and_return("firefox")
            allow(matcher).to receive(:on_active_application_changed)

            cosmic.send(:register_on_application_changed, matcher)
            cosmic.writer.close
            expect(cosmic.reader.read).to eq("firefox\n")
          end

          it "writes NOT FOUND when active_application is nil" do
            matcher = instance_double(Cosmic::Matcher)
            allow(matcher).to receive(:active_application).and_return(nil)
            allow(matcher).to receive(:on_active_application_changed)

            cosmic.send(:register_on_application_changed, matcher)
            cosmic.writer.close
            expect(cosmic.reader.read).to eq("NOT FOUND\n")
          end

          it "exits with 0 on Errno::EPIPE in notify" do
            # Close reader only — writer.puts then raises Errno::EPIPE
            # (closing the writer would raise IOError: closed stream instead).
            cosmic.reader.close
            expect { cosmic.send(:notify, "firefox") }.to raise_error(SystemExit) { |e|
              expect(e.status).to eq(0)
            }
          end
        end
      end
    end
  end
end
