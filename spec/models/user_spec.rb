# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create :user }

  describe '#consent_withdrawn_sample_metadata' do
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

  # This is supplied by the ancient rails-authorization-plugin which we have
  # intent to remove:
  # https://github.com/sanger/sequencescape/issues/2984
  # Currently it isn't triggering touch actions as expected on study,
  # resulting in the WH not updating
  describe '#has_no_role' do
    let(:study) { create :study_with_manager, updated_at: 2.years.ago }

    it 'updates the study updated_at timestamp' do
      # Make sure things are setup correctly first
      expect(study.reload.updated_at).to be < 1.hour.ago
      user = study.managers.first
      user.has_no_role('manager', study)
      expect(study.reload.updated_at).to be > 1.hour.ago
    end

    it 'updates the study updated_at timestamp with multiple managers' do
      # Make sure things are setup correctly first
      study.roles.first.users << create(:user)
      expect(study.reload.updated_at).to be < 1.hour.ago
      user = study.managers.first
      user.has_no_role('manager', study)
      expect(study.reload.updated_at).to be > 1.hour.ago
    end
  end
end
