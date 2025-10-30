# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Accession::Status, type: :model do
  let(:sample) { create(:sample) }
  let(:user) { create(:user) }
  let(:status_group) { create(:accession_status_group, submitting_user: user) }

  describe 'associations' do
    it { is_expected.to belong_to(:sample) }
    it { is_expected.to belong_to(:status_group).class_name('Accession::StatusGroup') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[queued failed]) }
  end

  describe '.create_for_sample' do
    let(:status) { described_class.create_for_sample(sample, status_group) }

    it 'creates a status with status queued' do
      expect(status.status).to eq('queued')
    end

    it 'associates the status with the given sample' do
      expect(status.sample).to eq(sample)
    end

    it 'associates the status with the given status group' do
      expect(status.status_group).to eq(status_group)
    end
  end

  describe '#mark_failed' do
    let(:status) { described_class.create_for_sample(sample, status_group) }

    before do
      status.mark_failed('Something went wrong')
    end

    it 'updates the status to failed' do
      expect(status.status).to eq('failed')
    end

    it 'sets the failure message' do
      expect(status.message).to eq('Something went wrong')
    end
  end
end
