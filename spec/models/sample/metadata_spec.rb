# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sample::Metadata do
  describe '#user_of_consent_withdrawn' do
    let(:user) { create :user }
    let(:sample) { create :sample }
    let(:sample_metadata) { create :sample_metadata_for_api }
    let(:sample_with_metadata) { create :sample, sample_metadata: }

    before { sample.sample_metadata.update(user_id_of_consent_withdrawn: user.id) }

    it 'returns the user that withdraw consent on the sample' do
      expect(sample.sample_metadata.user_of_consent_withdrawn).to eq(user)
    end

    it 'has a collected_by attribute' do
      expect(sample_with_metadata.sample_metadata.collected_by).to eq 'collected_by'
    end
  end
end
