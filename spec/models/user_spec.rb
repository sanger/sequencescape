# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create :user }

  describe '#consent_withdrawn_sample_metadata' do
    let(:samples) { create_list :sample, 4 }

    before { samples.each { |sample| sample.sample_metadata.update(user_id_of_consent_withdrawn: user.id) } }

    it 'returns the list of samples that this user has withdraw consent' do
      expect(user.consent_withdrawn_sample_metadata).to eq(samples.map(&:sample_metadata))
    end
  end

  shared_examples 'a role predicate' do
    context 'when checking an administrator is an administrator' do
      let(:user) { create :admin }
      let(:role_name) { 'administrator' }
      let(:authorizable) { nil }

      it { is_expected.to be true }
    end

    context 'when checking an administrator is an manager' do
      let(:user) { create :admin }
      let(:role_name) { 'manager' }
      let(:authorizable) { nil }

      it { is_expected.to be false }
    end

    context 'when checking an non-administrator is an administrator' do
      let(:user) { create :user }
      let(:role_name) { 'administrator' }
      let(:authorizable) { nil }

      it { is_expected.to be false }
    end

    context 'when checking an manager is an manager (generic)' do
      let(:study) { create :study_with_manager }
      let(:user) { study.managers.first }
      let(:role_name) { 'manager' }
      let(:authorizable) { nil }

      it { is_expected.to be true }
    end

    context 'when checking an manager of their study' do
      let(:study) { create :study_with_manager }
      let(:user) { study.managers.first }
      let(:role_name) { 'manager' }
      let(:authorizable) { study }

      it { is_expected.to be true }
    end

    context 'when checking an manager of a different study' do
      let(:study) { create :study_with_manager }
      let(:user) { study.managers.first }
      let(:role_name) { 'manager' }
      let(:authorizable) { create :study }

      it { is_expected.to be false }
    end
  end

  describe '#role?' do
    context 'without roles loaded' do
      subject { user.reload.role?(role_name, authorizable) }

      it_behaves_like 'a role predicate'
    end

    context 'with roles loaded' do
      subject do
        user.roles.load
        user.role?(role_name, authorizable)
      end

      it_behaves_like 'a role predicate'
    end
  end

  describe '#<role_name>?' do
    subject { user.public_send("#{role_name}?", authorizable) }

    it_behaves_like 'a role predicate'
  end

  describe '#<role_name>_of?' do
    subject { user.public_send("#{role_name}_of?", authorizable) }

    it_behaves_like 'a role predicate'
  end

  describe '#grant_role' do
    let(:user) { create :user }
    let(:study) { create :study }

    it 'adds a role to a user' do
      user.grant_role('administrator')
      expect(user).to be_an_administrator
    end

    it 'adds an authorized role to a user' do
      user.grant_role('owner', study)
      expect(user).to be_an_owner_of study
    end

    context 'when a role already exists' do
      before { create(:user).grant_role('owner', study) }

      it "doesn't create a new role" do
        expect { user.grant_role('owner', study) }.not_to(change { study.roles.reload.count })
      end
    end

    it 'updates the study updated_at timestamp' do
      study.update(updated_at: 1.year.ago)
      study.reload
      expect { user.grant_role('administrator', study) }.to(change { study.reload.updated_at })
    end
  end

  describe '#remove_role' do
    let(:study) { create :study_with_manager, updated_at: 2.years.ago }

    it 'updates the study updated_at timestamp' do
      # We make sure that defining a study with a manager triggers study update
      expect(study.reload.updated_at).to be_within(1.hour).of Time.zone.now

      user = study.managers.first

      study.update(updated_at: 1.hour.ago)

      expect(study.reload.updated_at).not_to be_within(5.minutes).of Time.zone.now
      user.remove_role('manager', study)
      expect(study.reload.updated_at).to be_within(5.minutes).of Time.zone.now
    end

    it 'updates the study updated_at timestamp with multiple managers' do
      # Make sure things are setup correctly first
      study.roles.first.users << create(:user)

      # We make sure that defining a study with a manager triggers study update
      expect(study.reload.updated_at).to be_within(1.hour).of Time.zone.now

      user = study.managers.first
      study.update(updated_at: 1.hour.ago)

      expect(study.reload.updated_at).not_to be_within(5.minutes).of Time.zone.now
      user.remove_role('manager', study)
      expect(study.reload.updated_at).to be_within(5.minutes).of Time.zone.now
    end
  end
end
