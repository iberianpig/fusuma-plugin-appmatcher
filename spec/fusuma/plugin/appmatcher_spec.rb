# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fusuma::Plugin::Appmatcher do
  it 'has a version number' do
    expect(Fusuma::Plugin::Appmatcher::VERSION).not_to be nil
  end
end
