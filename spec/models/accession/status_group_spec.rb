# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accession::StatusGroup, type: :model do
  let(:user) { create(:user) }
  let(:status_group) { described_class.create!(submitting_user: user) }

  describe 'associations' do
    it { is_expected.to belong_to(:submitting_user).class_name('User') }
    it { is_expected.to belong_to(:accession_group).optional }
    it { is_expected.to have_many(:statuses).class_name('Accession::Status').dependent(:destroy) }
  end

  describe '#all_statuses_processed?' do
    context 'when there is at least one queued status' do
      before do
        create(:accession_status, status_group: status_group, status: 'queued')
        create(:accession_status, status_group: status_group, status: 'failed')
      end

      it 'returns false' do
        expect(status_group.all_statuses_processed?).to be false
      end
    end

    context 'when there are no queued statuses' do
      before do
        create(:accession_status, status_group: status_group, status: 'failed')
        create(:accession_status, status_group: status_group, status: 'failed')
      end

      it 'returns true' do
        expect(status_group.all_statuses_processed?).to be true
      end
    end
  end
end
