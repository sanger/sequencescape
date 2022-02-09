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
end
