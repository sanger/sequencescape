# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sample::Metadata, type: :model do
  describe '#user_of_consent_withdrawn' do
    let(:user) { create :user }
    let(:sample) { create :sample }

    before do
      sample.sample_metadata.update(user_id_of_consent_withdrawn: user.id)
    end

    it 'returns the user that withdraw consent on the sample' do
      expect(sample.sample_metadata.user_of_consent_withdrawn).to eq(user)
    end
  end
end
