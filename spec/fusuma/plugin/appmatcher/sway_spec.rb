# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

module Fusuma
  module Plugin
    module Appmatcher
      RSpec.describe Sway do
        describe ".available?" do
          # available? searches PATH in pure Ruby (no external `which`,
          # which is not installed on minimal systems like Arch containers).
          context "when swaymsg is found in PATH" do
            it "returns true" do
              Dir.mktmpdir do |dir|
                exe = File.join(dir, "swaymsg")
                File.write(exe, "")
                File.chmod(0o755, exe)
                allow(ENV).to receive(:fetch).and_call_original
                allow(ENV).to receive(:fetch).with("PATH", "").and_return(dir)

                expect(described_class.available?).to be true
              end
            end
          end

          context "when swaymsg is not in PATH" do
            it "returns false" do
              Dir.mktmpdir do |dir|
                allow(ENV).to receive(:fetch).and_call_original
                allow(ENV).to receive(:fetch).with("PATH", "").and_return(dir)

                expect(described_class.available?).to be false
              end
            end
          end

          context "when PATH entry contains a directory named swaymsg" do
            it "returns false" do
              Dir.mktmpdir do |dir|
                Dir.mkdir(File.join(dir, "swaymsg"))
                allow(ENV).to receive(:fetch).and_call_original
                allow(ENV).to receive(:fetch).with("PATH", "").and_return(dir)

                expect(described_class.available?).to be false
              end
            end
          end
        end

        describe "#initialize" do
          it "creates an IO pipe" do
            sway = described_class.new
            expect(sway.reader).to be_a(IO)
            expect(sway.writer).to be_a(IO)
            sway.reader.close
            sway.writer.close
          end
        end

        describe Sway::Matcher do
          let(:matcher) { described_class.new }

          describe "#extract_app_name" do
            subject { matcher.send(:extract_app_name, container) }

            context "when container is nil" do
              let(:container) { nil }
              it { is_expected.to be_nil }
            end

            context "when container has app_id (Wayland native)" do
              let(:container) { {"app_id" => "firefox", "name" => "Mozilla Firefox"} }
              it { is_expected.to eq "firefox" }
            end

            context "when container has empty app_id but has window_properties (XWayland)" do
              let(:container) do
                {
                  "app_id" => nil,
                  "window_properties" => {"class" => "Google-chrome"}
                }
              end
              it { is_expected.to eq "Google-chrome" }
            end

            context "when container has empty string app_id" do
              let(:container) do
                {
                  "app_id" => "",
                  "window_properties" => {"class" => "Slack"}
                }
              end
              it { is_expected.to eq "Slack" }
            end

            context "when container has both app_id and window_properties" do
              let(:container) do
                {
                  "app_id" => "alacritty",
                  "window_properties" => {"class" => "SomeClass"}
                }
              end
              it "prefers app_id" do
                is_expected.to eq "alacritty"
              end
            end
          end

          describe "#find_focused_node" do
            subject { matcher.send(:find_focused_node, tree) }

            context "when root node is focused" do
              let(:tree) { {"focused" => true, "app_id" => "root"} }
              it { is_expected.to eq tree }
            end

            context "when a child node is focused" do
              let(:tree) do
                {
                  "focused" => false,
                  "nodes" => [
                    {"focused" => false, "app_id" => "unfocused"},
                    {"focused" => true, "app_id" => "focused_app"}
                  ]
                }
              end
              it { is_expected.to eq({"focused" => true, "app_id" => "focused_app"}) }
            end

            context "when a floating node is focused" do
              let(:tree) do
                {
                  "focused" => false,
                  "nodes" => [],
                  "floating_nodes" => [
                    {"focused" => true, "app_id" => "floating_app"}
                  ]
                }
              end
              it { is_expected.to eq({"focused" => true, "app_id" => "floating_app"}) }
            end

            context "when deeply nested node is focused" do
              let(:tree) do
                {
                  "focused" => false,
                  "nodes" => [
                    {
                      "focused" => false,
                      "nodes" => [
                        {"focused" => true, "app_id" => "deep_app"}
                      ]
                    }
                  ]
                }
              end
              it { is_expected.to eq({"focused" => true, "app_id" => "deep_app"}) }
            end

            context "when no node is focused" do
              let(:tree) do
                {
                  "focused" => false,
                  "nodes" => [
                    {"focused" => false, "app_id" => "app1"}
                  ]
                }
              end
              it { is_expected.to be_nil }
            end
          end

          describe "#collect_app_names" do
            subject { matcher.send(:collect_app_names, tree) }

            let(:tree) do
              {
                "app_id" => nil,
                "nodes" => [
                  {"app_id" => "firefox"},
                  {"app_id" => "alacritty"},
                  {
                    "app_id" => nil,
                    "nodes" => [
                      {"app_id" => "code"}
                    ]
                  }
                ],
                "floating_nodes" => [
                  {"app_id" => nil, "window_properties" => {"class" => "Slack"}}
                ]
              }
            end

            it "collects all app names from the tree" do
              expect(subject).to contain_exactly("firefox", "alacritty", "code", "Slack")
            end
          end

          describe "#running_applications" do
            subject { matcher.running_applications }

            let(:tree_json) do
              {
                "nodes" => [
                  {"app_id" => "firefox"},
                  {"app_id" => "alacritty"},
                  {"app_id" => "firefox"} # duplicate
                ]
              }.to_json
            end

            before do
              allow(matcher).to receive(:`).with("swaymsg -t get_tree").and_return(tree_json)
            end

            it "returns unique app names" do
              expect(subject).to contain_exactly("firefox", "alacritty")
            end
          end

          describe "#active_application" do
            subject { matcher.active_application }

            let(:tree_json) do
              {
                "focused" => false,
                "nodes" => [
                  {"focused" => true, "app_id" => "active_app"}
                ]
              }.to_json
            end

            before do
              allow(matcher).to receive(:`).with("swaymsg -t get_tree").and_return(tree_json)
            end

            it "returns the focused app name" do
              expect(subject).to eq "active_app"
            end
          end

          describe "#on_active_application_changed" do
            # Build a sway window event line as emitted by
            # `swaymsg -m -t subscribe '["window"]'`
            def focus_event(app_id)
              {
                "change" => "focus",
                "container" => {"app_id" => app_id}
              }.to_json + "\n"
            end

            # Stub Open3.popen3 to feed the given lines as swaymsg stdout.
            def stub_subscribe(lines)
              stdout = StringIO.new(lines.join)
              stderr = StringIO.new("")
              stdin = StringIO.new
              wait_thr = double("wait_thr")
              allow(Open3).to receive(:popen3)
                .with("swaymsg", "-m", "-t", "subscribe", '["window"]')
                .and_yield(stdin, stdout, stderr, wait_thr)
              stdin
            end

            # A clean swaymsg exit raises so on_active_application_changed
            # resubscribes via its `rescue => e; sleep 1; retry` loop.
            # The sleep stub raises SystemExit to break out of that infinite
            # retry loop in tests (SystemExit is not a StandardError, so
            # `rescue => e` does not catch it).
            before do
              allow(Fusuma::MultiLogger).to receive(:error)
              allow(matcher).to receive(:sleep).and_raise(SystemExit)
            end

            # Runs the subscription until the stubbed stdout is exhausted
            # (then the sleep stub raises SystemExit) and returns yielded names.
            def watch_until_exit
              yielded = []
              expect {
                matcher.on_active_application_changed { |name| yielded << name }
              }.to raise_error(SystemExit)
              yielded
            end

            it "yields app name on focus event" do
              stub_subscribe([focus_event("firefox")])
              expect(watch_until_exit).to eq(["firefox"])
            end

            it "ignores non-focus events" do
              other = {"change" => "title", "container" => {"app_id" => "kitty"}}.to_json + "\n"
              stub_subscribe([other, focus_event("alacritty")])
              expect(watch_until_exit).to eq(["alacritty"])
            end

            it "skips invalid JSON lines" do
              allow(Fusuma::MultiLogger).to receive(:warn)
              stub_subscribe(["not json\n", focus_event("kitty")])
              expect(watch_until_exit).to eq(["kitty"])
              expect(Fusuma::MultiLogger).to have_received(:warn).with(/Failed to parse/)
            end

            it "retries when swaymsg exits cleanly" do
              # A clean swaymsg exit (stdout EOF, no exception) must not stop
              # the watcher silently; it raises and enters the retry loop.
              stub_subscribe([])
              watch_until_exit
              expect(Fusuma::MultiLogger).to have_received(:error).with(/swaymsg .*exited/)
            end

            it "logs and retries when swaymsg is missing" do
              allow(Open3).to receive(:popen3)
                .with("swaymsg", "-m", "-t", "subscribe", '["window"]')
                .and_raise(Errno::ENOENT)

              watch_until_exit

              expect(Fusuma::MultiLogger).to have_received(:error).with(/swaymsg command not found/)
            end
          end
        end
      end
    end
  end
end
