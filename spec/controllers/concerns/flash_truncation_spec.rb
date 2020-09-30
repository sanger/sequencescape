# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FlashTruncation do
  let(:dummy_class) { Struct.new(:session) { include FlashTruncation } }

  describe '#max_flash_size' do
    subject { dummy_class.new(session).max_flash_size }

    context 'when the session is 2 bytes' do
      let(:session) { {} }
      it { is_expected.to eq 2046 }
    end

    context 'when the session is 32 bytes' do
      let(:session) { { user_name: 'Testy McTestface' } }
      it { is_expected.to eq 2016 }
    end
  end

  describe '#truncate_flash' do
    subject { dummy_class.new({}).truncate_flash(flash, 16) }

    context 'when the flash is a string smaller than the max_size' do
      let(:flash) { 'A short string' }
      it { is_expected.to eq flash }
    end

    context 'when the flash is a string larger than the max_size' do
      let(:flash) { 'A longer st...' }
      it { is_expected.to eq flash }
    end

    context 'when the flash is an array smaller than the max_size' do
      let(:flash) { %w[shrt array] }
      it { is_expected.to eq flash }
    end

    context 'when the flash is an array larger than the max_size' do
      let(:flash) { ['longer', 'array', 'oh no'] }
      it { is_expected.to eq ['longer', 'a...'] }
    end
  end
end
