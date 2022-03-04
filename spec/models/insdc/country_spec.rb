# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Insdc::Country, type: :model do
  context 'without a name' do
    subject { build :insdc_country, name: nil }

    it { is_expected.not_to be_valid }
  end

  context 'without a sort_priority' do
    subject { build :insdc_country, sort_priority: nil }

    it { is_expected.not_to be_valid }
  end

  context 'without a validation_state' do
    subject { build :insdc_country, validation_state: nil }

    it { is_expected.not_to be_valid }
  end

  describe '#invalid!' do
    let(:country) { build :insdc_country, validation_state: 'valid' }

    it 'marks a country as invalid' do
      country.invalid!
      expect(country).to be_invalid_state
    end
  end

  describe '#options' do
    subject(:options) { described_class.options }

    before do
      create :insdc_country, name: 'Excellent land'
      create :insdc_country, name: 'Amazing land'
      create :insdc_country, name: 'Best land'
      create :insdc_country, :high_priority, name: 'Cool land'
      create :insdc_country, :invalid, name: 'Dead land'
    end

    it { is_expected.to be_an Array }

    it 'excludes invalid options' do
      expect(options).not_to include('Dead land')
    end

    it 'sorts high priority first' do
      expect(options.first).to eq('Cool land')
    end

    it 'sorts the remaining options alphabetically' do
      _, *remaining = options
      expect(remaining).to eq(['Amazing land', 'Best land', 'Excellent land'])
    end
  end
end
