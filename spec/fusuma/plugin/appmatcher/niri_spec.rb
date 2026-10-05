# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fusuma/plugin/appmatcher/niri"

module Fusuma
  module Plugin
    module Appmatcher
      RSpec.describe Niri do
        describe ".available?" do
          it "returns true when niri is executable in PATH" do
            Dir.mktmpdir do |dir|
              executable = File.join(dir, "niri")
              File.write(executable, "")
              File.chmod(0o755, executable)
              allow(ENV).to receive(:fetch).and_call_original
              allow(ENV).to receive(:fetch).with("PATH", "").and_return(dir)

              expect(described_class.available?).to be true
            end
          end

          it "returns false when niri is not in PATH" do
            Dir.mktmpdir do |dir|
              allow(ENV).to receive(:fetch).and_call_original
              allow(ENV).to receive(:fetch).with("PATH", "").and_return(dir)

              expect(described_class.available?).to be false
            end
          end
        end

        describe "#initialize" do
          it "creates an IO pipe" do
            niri = described_class.new
            expect(niri.reader).to be_a(IO)
            expect(niri.writer).to be_a(IO)
            niri.reader.close
            niri.writer.close
          end
        end

        describe Niri::Matcher do
          let(:matcher) { described_class.new }
          let(:windows) do
            [
              {"id" => 1, "app_id" => "org.example.Editor", "is_focused" => false},
              {"id" => 2, "app_id" => "firefox", "is_focused" => true}
            ]
          end

          before do
            allow(Open3).to receive(:capture3).with("niri", "msg", "-j", "windows")
              .and_return([JSON.generate(windows), "", instance_double(Process::Status, success?: true)])
          end

          it "returns unique application ids" do
            expect(matcher.running_applications).to eq(["org.example.Editor", "firefox"])
          end

          it "returns the focused window application id" do
            expect(matcher.active_application).to eq("firefox")
          end

          it "returns nil when no window is focused" do
            allow(Open3).to receive(:capture3).and_return(
              [JSON.generate([{"app_id" => "firefox", "is_focused" => false}]), "", instance_double(Process::Status, success?: true)]
            )

            expect(matcher.active_application).to be_nil
          end
        end
      end
    end
  end
end
