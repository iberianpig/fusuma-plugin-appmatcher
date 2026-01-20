# frozen_string_literal: true

require "spec_helper"
require "fusuma/plugin/appmatcher/hyprland"

module Fusuma
  module Plugin
    module Appmatcher
      RSpec.describe Hyprland do
        let(:hyprland) { Hyprland.new }

        describe "#initialize" do
          it "creates IO pipe for reader" do
            expect(hyprland.reader).to be_a(IO)
          end

          it "creates IO pipe for writer" do
            expect(hyprland.writer).to be_a(IO)
          end
        end

        describe Hyprland::Matcher do
          let(:matcher) { Hyprland::Matcher.new }

          before do
            allow(ENV).to receive(:[]).and_call_original
            allow(ENV).to receive(:fetch).and_call_original
          end

          describe "#active_application" do
            context "when hyprctl returns valid JSON" do
              before do
                allow(matcher).to receive(:`).with("hyprctl -j activewindow 2>/dev/null")
                  .and_return('{"class":"kitty","title":"terminal"}')
              end

              it "returns the window class" do
                expect(matcher.active_application).to eq("kitty")
              end
            end

            context "when hyprctl returns empty string" do
              before do
                allow(matcher).to receive(:`).with("hyprctl -j activewindow 2>/dev/null")
                  .and_return("")
              end

              it "returns nil" do
                expect(matcher.active_application).to be_nil
              end
            end

            context "when hyprctl returns empty object" do
              before do
                allow(matcher).to receive(:`).with("hyprctl -j activewindow 2>/dev/null")
                  .and_return("{}")
              end

              it "returns nil" do
                expect(matcher.active_application).to be_nil
              end
            end

            context "when hyprctl returns invalid JSON" do
              before do
                allow(matcher).to receive(:`).with("hyprctl -j activewindow 2>/dev/null")
                  .and_return("not json")
              end

              it "returns nil" do
                expect(matcher.active_application).to be_nil
              end
            end
          end

          describe "#running_applications" do
            context "when hyprctl returns valid clients" do
              before do
                allow(matcher).to receive(:`).with("hyprctl clients -j 2>/dev/null")
                  .and_return('[{"class":"kitty"},{"class":"firefox"},{"class":"kitty"}]')
              end

              it "returns unique window classes" do
                expect(matcher.running_applications).to contain_exactly("kitty", "firefox")
              end
            end

            context "when hyprctl returns empty array" do
              before do
                allow(matcher).to receive(:`).with("hyprctl clients -j 2>/dev/null")
                  .and_return("[]")
              end

              it "returns empty array" do
                expect(matcher.running_applications).to eq([])
              end
            end

            context "when hyprctl returns empty string" do
              before do
                allow(matcher).to receive(:`).with("hyprctl clients -j 2>/dev/null")
                  .and_return("")
              end

              it "returns empty array" do
                expect(matcher.running_applications).to eq([])
              end
            end
          end
        end
      end
    end
  end
end
