# frozen_string_literal: true

require "spec_helper"

module Fusuma
  module Plugin
    module Appmatcher
      module KwinScripts
        RSpec.describe Installer do
          let(:installer) { described_class.new }
          let(:user) { UserSwitcher::User.new("user", 1000) }

          describe "#install" do
            before do
              allow(Process).to receive(:waitpid)
              allow(installer).to receive(:as_user).and_yield(user) do |block_context|
                allow(block_context).to receive(:source_path).and_return("source_path")
                allow(block_context).to receive(:install_path).with(user.username).and_return("install_path")
                allow(block_context).to receive(:user_script_dir).with(user.username)
                allow(block_context).to receive(:load_and_run_script).with(user)
              end
              allow(FileUtils).to receive(:mkdir_p)
            end

            it "should copy file to user's dir" do
              expect(FileUtils).to receive(:cp_r).with(any_args)
              installer.install
            end

            it "should load and run the script" do
              allow(FileUtils).to receive(:cp_r)
              expect(installer).to receive(:as_user)
              installer.install
            end
          end

          describe "#uninstall" do
            before do
              allow(Process).to receive(:waitpid)
              allow(installer).to receive(:as_user).and_yield(user) do |block_context|
                allow(block_context).to receive(:source_path).and_return("source_path")
                allow(block_context).to receive(:install_path).with(user.username).and_return("install_path")
                allow(block_context).to receive(:user_script_dir).with(user.username)
                allow(block_context).to receive(:unload_script).with(user)
              end
            end

            context "when script is installed" do
              before do
                allow(installer).to receive(:installed?).and_return(true)
              end

              it "should remove file from user's dir" do
                expect(FileUtils).to receive(:rm_r).with(any_args)
                installer.uninstall
              end
            end

            context "when script is NOT installed" do
              before do
                allow(installer).to receive(:installed?).and_return(false)
              end

              it "should NOT execute" do
                expect(installer).not_to receive(:as_user)
                installer.uninstall
              end
            end
          end

          describe "#enabled?" do
            let(:mock_bus) { double("DBus::SessionBus") }
            let(:mock_service) { double("DBus::Service") }
            let(:mock_scripting) { double("DBus::ProxyObject") }

            before do
              allow(installer).to receive(:installed?).and_return(true)
              allow(UserSwitcher).to receive(:login_user).and_return(user)
              allow(ENV).to receive(:[]=)
              allow(DBus).to receive(:session_bus).and_return(mock_bus)
              allow(mock_bus).to receive(:service).with("org.kde.KWin").and_return(mock_service)
              allow(mock_service).to receive(:object).with("/Scripting").and_return(mock_scripting)
              allow(mock_scripting).to receive(:introspect)
              allow(mock_scripting).to receive(:default_iface=)
            end

            context "when script is loaded" do
              before do
                allow(mock_scripting).to receive(:isScriptLoaded).with("appmatcher-kde").and_return([true])
              end

              it "returns true" do
                expect(installer.enabled?).to be true
              end
            end

            context "when script is not loaded" do
              before do
                allow(mock_scripting).to receive(:isScriptLoaded).with("appmatcher-kde").and_return([false])
              end

              it "returns false" do
                expect(installer.enabled?).to be false
              end
            end

            context "when DBus error occurs" do
              before do
                allow(mock_scripting).to receive(:isScriptLoaded).and_raise(DBus::Error, "Connection failed")
              end

              it "returns false" do
                expect(installer.enabled?).to be false
              end
            end

            context "when script is not installed" do
              before do
                allow(installer).to receive(:installed?).and_return(false)
              end

              it "returns false" do
                expect(installer.enabled?).to be false
              end
            end
          end
        end
      end
    end
  end
end
