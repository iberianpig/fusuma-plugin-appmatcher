# frozen_string_literal: true

require "spec_helper"

module Fusuma
  module Plugin
    module Appmatcher
      module GnomeExtensions
        RSpec.describe Installer do
          describe "#install" do
            it "should copy file to users dir"
          end
          describe "#uninstall" do
            context "when extension is NOT installed" do
              it "should remove file to users dir"
            end
            context "when extension is NOT installed" do
              it "should NOT execute"
            end
          end
          describe "#installed?" do
            it "check extension is in the installed path"
          end
        end
      end
    end
  end
end
