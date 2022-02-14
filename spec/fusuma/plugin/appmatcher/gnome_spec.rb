# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/plugin/appmatcher/gnome"

module Fusuma
  module Plugin
    module Appmatcher
      RSpec.describe Gnome do
        it "requires ruby-dbus" do
          expect(DBus).not_to be nil
        end
      end
    end
  end
end
