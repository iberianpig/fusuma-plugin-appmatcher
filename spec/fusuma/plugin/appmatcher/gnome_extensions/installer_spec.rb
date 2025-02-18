# frozen_string_literal: true

require "spec_helper"

module Fusuma
  module Plugin
    module Appmatcher
      module GnomeExtensions
        RSpec.describe Installer do
          let(:installer) { described_class.new }
          let(:user) { UserSwitcher::User.new("user") }

          describe "#install" do
            before do
              allow(Process).to receive(:waitpid)
              allow(installer).to receive(:as_user).and_yield(user) do |block_context|
                allow(block_context).to receive(:source_path).and_return("source_path")
                allow(block_context).to receive(:install_path).with(user.username).and_return("install_path")
                allow(block_context).to receive(:user_extension_dir).with(user.username)
              end
            end
            it "should copy file to user's dir" do
              expect(FileUtils).to receive(:cp_r).with(any_args)
              installer.install
            end
          end

          describe "#uninstall" do
            before do
              allow(Process).to receive(:waitpid)
              allow(installer).to receive(:as_user).and_yield(user) do |block_context|
                allow(block_context).to receive(:source_path).and_return("source_path")
                allow(block_context).to receive(:install_path).with(user.username).and_return("install_path")
                allow(block_context).to receive(:user_extension_dir).with(user.username)
              end
            end

            context "when extension is installed" do
              before do
                allow(installer).to receive(:installed?).and_return(true)
              end
              it "should remove file to user's dir" do
                expect(FileUtils).to receive(:rm_r).with(any_args)
                installer.uninstall
              end
            end

            context "when extension is NOT installed" do
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
            it "returns true if the gnome extension is enabled" do
              allow(installer).to receive(:`).with("gsettings get org.gnome.shell enabled-extensions").and_return("['appmatcher@iberianpig.dev']")
              expect(installer.enabled?).to be true
            end

            it "returns false if the gnome extension is not enabled" do
              allow(installer).to receive(:`).with("gsettings get org.gnome.shell enabled-extensions").and_return("[]")
              expect(installer.enabled?).to be false
            end
          end
        end
      end
    end
  end
end
