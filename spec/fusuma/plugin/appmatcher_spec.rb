# frozen_string_literal: true

require 'spec_helper'

module Fusuma
  module Plugin
    RSpec.describe Appmatcher do
      it 'has a version number' do
        expect(Appmatcher::VERSION).not_to be nil
      end

      describe '#backend_klass' do
        context 'when XDG_CURRENT_DESKTOP is UNKNOWN' do
          before { allow(Appmatcher).to receive(:xdg_current_desktop).and_return('UNKNOWN') }
          it { expect { Appmatcher.backend_klass }.to raise_error }
        end

        context 'when XDG_SESSION_TYPE is x11' do
          before { allow(Appmatcher).to receive(:xdg_session_type).and_return('x11') }
          it { expect(Appmatcher.backend_klass).to eq Appmatcher::X11 }
        end

        context 'when XDG_SESSION_TYPE is wayland' do
          before { allow(Appmatcher).to receive(:xdg_session_type).and_return('wayland') }

          context 'when XDG_CURRENT_DESKTOP is ubuntu:GNOME' do
            before { allow(Appmatcher).to receive(:xdg_current_desktop).and_return('ubuntu:GNOME') }
            it { expect(Appmatcher.backend_klass).to eq Appmatcher::Gnome }
          end

          context 'when XDG_CURRENT_DESKTOP is UNKNOWN' do
            before { allow(Appmatcher).to receive(:xdg_current_desktop).and_return('UNKNOWN') }
            it { expect { Appmatcher.backend_klass }.to raise_error }
          end
        end
      end
    end
  end
end
