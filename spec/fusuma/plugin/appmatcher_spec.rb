# frozen_string_literal: true

require "spec_helper"

module Fusuma
  module Plugin
    RSpec.describe Appmatcher do
      it "has a version number" do
        expect(Appmatcher::VERSION).not_to be nil
      end

      describe "#backend_klass" do
        subject { Appmatcher.backend_klass }
        context "when XDG_SESSION_TYPE is x11" do
          before { allow(Appmatcher).to receive(:xdg_session_type).and_return("x11") }
          it { is_expected.to eq Appmatcher::X11 }
        end

        context "when XDG_SESSION_TYPE is wayland" do
          before { allow(Appmatcher).to receive(:xdg_session_type).and_return("wayland") }

          context "when XDG_CURRENT_DESKTOP is ubuntu:GNOME" do
            before { allow(Appmatcher).to receive(:xdg_current_desktop).and_return("ubuntu:GNOME") }

            context "when gnome-extension is enabled" do
              before do
                allow_any_instance_of(Appmatcher::GnomeExtensions::Installer).to receive(:enabled?).and_return(true)
              end
              it { is_expected.to eq Appmatcher::GnomeExtension }
            end

            context "when gnome-extension is NOT enabled" do
              before do
                allow_any_instance_of(Appmatcher::GnomeExtensions::Installer).to receive(:enabled?).and_return(false)
              end
              it { is_expected.to eq Appmatcher::UnsupportedBackend }
            end
          end

          context "when XDG_CURRENT_DESKTOP is sway" do
            before { allow(Appmatcher).to receive(:xdg_current_desktop).and_return("sway") }

            context "when swaymsg is available" do
              before do
                allow(Appmatcher::Sway).to receive(:available?).and_return(true)
              end
              it { is_expected.to eq Appmatcher::Sway }
            end

            context "when swaymsg is NOT available" do
              before do
                allow(Appmatcher::Sway).to receive(:available?).and_return(false)
              end
              it { is_expected.to eq Appmatcher::UnsupportedBackend }
            end
          end

          context "when XDG_CURRENT_DESKTOP is Sway (capitalized)" do
            before do
              allow(Appmatcher).to receive(:xdg_current_desktop).and_return("Sway")
              allow(Appmatcher::Sway).to receive(:available?).and_return(true)
            end
            it { is_expected.to eq Appmatcher::Sway }
          end

          context "when XDG_CURRENT_DESKTOP is UNKNOWN" do
            before do
              allow(Appmatcher).to receive(:xdg_current_desktop).and_return("UNKNOWN")
              allow(MultiLogger).to receive(:error)
            end
            it { is_expected.to eq Appmatcher::UnsupportedBackend }
          end

          context "when XDG_CURRENT_DESKTOP is Hyprland" do
            before { allow(Appmatcher).to receive(:xdg_current_desktop).and_return("Hyprland") }

            context "when Hyprland socket is available" do
              before do
                allow(Appmatcher).to receive(:hyprland_available?).and_return(true)
              end
              it { is_expected.to eq Appmatcher::Hyprland }
            end

            context "when Hyprland socket is NOT available" do
              before do
                allow(Appmatcher).to receive(:hyprland_available?).and_return(false)
              end
              it { is_expected.to eq Appmatcher::UnsupportedBackend }
            end
          end
        end
      end

      describe ".hyprland_available?" do
        subject { Appmatcher.hyprland_available? }

        context "when HYPRLAND_INSTANCE_SIGNATURE is not set" do
          before do
            allow(ENV).to receive(:[]).and_call_original
            allow(ENV).to receive(:[]).with("HYPRLAND_INSTANCE_SIGNATURE").and_return(nil)
          end
          it { is_expected.to be false }
        end

        context "when HYPRLAND_INSTANCE_SIGNATURE is set" do
          before do
            allow(ENV).to receive(:[]).and_call_original
            allow(ENV).to receive(:[]).with("HYPRLAND_INSTANCE_SIGNATURE").and_return("test_instance")
            allow(ENV).to receive(:fetch).and_call_original
            allow(ENV).to receive(:fetch).with("XDG_RUNTIME_DIR", "/tmp").and_return("/run/user/1000")
          end

          context "when socket file exists" do
            before do
              allow(File).to receive(:exist?).and_call_original
              allow(File).to receive(:exist?)
                .with("/run/user/1000/hypr/test_instance/.socket2.sock")
                .and_return(true)
            end
            it { is_expected.to be true }
          end

          context "when socket file does not exist" do
            before do
              allow(File).to receive(:exist?).and_call_original
              allow(File).to receive(:exist?)
                .with("/run/user/1000/hypr/test_instance/.socket2.sock")
                .and_return(false)
              allow(File).to receive(:exist?)
                .with("/tmp/hypr/test_instance/.socket2.sock")
                .and_return(false)
            end
            it { is_expected.to be false }
          end
        end
      end
    end
  end
end
