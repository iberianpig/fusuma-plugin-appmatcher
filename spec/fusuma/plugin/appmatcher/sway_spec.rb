# frozen_string_literal: true

require "spec_helper"

module Fusuma
  module Plugin
    module Appmatcher
      RSpec.describe Sway do
        describe ".available?" do
          subject { described_class.available? }

          context "when swaymsg command exists" do
            before do
              allow(described_class).to receive(:system).with("which swaymsg > /dev/null 2>&1").and_return(true)
            end
            it { is_expected.to be true }
          end

          context "when swaymsg command does not exist" do
            before do
              allow(described_class).to receive(:system).with("which swaymsg > /dev/null 2>&1").and_return(false)
            end
            it { is_expected.to be false }
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
        end
      end
    end
  end
end
