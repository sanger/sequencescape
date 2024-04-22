# frozen_string_literal: true

require 'rails_helper'

describe ExternalReleaseEvent do
  describe '::create_for_asset!' do
    subject { described_class.create_for_asset!(asset, sendmail) }

    let(:asset) { build(:lane, aliquots:, external_release: true) }
    let(:aliquots) { [study_a, study_a, study_b].map { |s| build(:aliquot, study: s) } }
    let(:expected_recipients) { [user_on_multiple_studies.email, user_on_single_study.email] }
    let(:expected_message) { 'Data to be released externally set true' }

    let!(:user_without_mail) { create(:manager, email: '', roles: [study_a_managers]) }
    let!(:user_on_multiple_studies) do
      create(:manager, email: 'test@example.com', roles: [study_a_managers, study_b_managers])
    end
    let!(:user_on_single_study) { create(:manager, email: 'test2@example.com', roles: [study_b_managers]) }

    let(:study_a) { create(:study) }
    let(:study_b) { create(:study) }

    let(:study_a_managers) { create(:manager_role, authorizable: study_a) }
    let(:study_b_managers) { create(:manager_role, authorizable: study_b) }

    context 'when sendmail is true' do
      let(:sendmail) { true }

      before do
        expect(EventfulMailer).to receive(:confirm_external_release_event)
          .with(expected_recipients, asset, expected_message, nil, 'No Milestone')
          .and_call_original
      end

      it { is_expected.to be_a described_class }
    end
  end
end
