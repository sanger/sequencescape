# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AccessionService do
  describe '.select_for_study' do
    context 'when given an open study' do
      let(:study) { create(:open_study) }

      it 'returns ENAService' do
        expect(described_class.select_for_study(study)).to be_a(AccessionService::ENAService)
      end
    end

    context 'when given a managed study' do
      let(:study) { create(:managed_study) }

      it 'returns EGAService' do
        expect(described_class.select_for_study(study)).to be_a(AccessionService::EGAService)
      end
    end

    context 'when given a study with other data release strategy' do
      let(:study) { create(:not_app_study) }

      it 'returns NoService' do
        expect(described_class.select_for_study(study)).to be_a(AccessionService::NoService)
      end
    end
  end
end
