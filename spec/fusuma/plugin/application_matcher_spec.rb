# frozen_string_literal: true

RSpec.describe Fusuma::Plugin::ApplicationMatcher do
  it 'has a version number' do
    expect(Fusuma::Plugin::ApplicationMatcher::VERSION).not_to be nil
  end

  it 'does something useful' do
    expect(false).to eq(true)
  end
end
