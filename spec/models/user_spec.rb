# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#consent_withdrawn_sample_metadata' do
    let(:user) { create :user }
    let(:samples) { create_list :sample, 4 }

    before do
      samples.each do |sample|
        sample.sample_metadata.update(user_id_of_consent_withdrawn: user.id)
      end
    end

    it 'returns the list of samples that this user has withdraw consent' do
      expect(user.consent_withdrawn_sample_metadata).to eq(samples.map(&:sample_metadata))
    end
  end
end
