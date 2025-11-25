# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Accession::SampleStatus, type: :model do
  let(:sample) { create(:sample) }

  describe 'associations' do
    it { is_expected.to belong_to(:sample) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[queued failed]) }
  end

  describe '.create_for_sample' do
    let(:sample_status) { described_class.create_for_sample(sample) }

    it 'creates a status with status queued' do
      expect(sample_status.status).to eq('queued')
    end

    it 'associates the status with the given sample' do
      expect(sample_status.sample).to eq(sample)
    end
  end

  describe '.find_latest!' do
    before do
      create(:accession_sample_status, sample: sample, status: 'queued', created_at: 3.days.ago)
      create(:accession_sample_status, sample: sample, status: 'failed', created_at: 2.days.ago)
      create(:accession_sample_status, sample: sample, status: 'failed', created_at: 1.day.ago)
      create(:accession_sample_status, sample: sample, status: 'processing', created_at: 0.days.ago)
    end

    it 'returns the most recent status for the sample' do
      latest_status = described_class.find_latest!(sample)
      expect(latest_status.status).to eq('processing')
    end

    it 'returns the most recent status for the sample filtered by status' do
      latest_failed_status = described_class.find_latest!(sample, status: 'failed')
      expect(latest_failed_status.created_at).to be_within(1.second).of(1.day.ago)
    end

    it 'raises an error if no status exists for the sample' do
      another_sample = create(:sample)
      expect do
        described_class.find_latest!(another_sample)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'raises an error if no status exists for the sample with the given status' do
      expect do
        described_class.find_latest!(sample, status: 'aborted')
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '.find_latest_and_update!' do
    before do
      create(:accession_sample_status, sample: sample, status: 'failed')
      create(:accession_sample_status, sample: sample, status: 'queued')
    end

    it 'updates the most recent status for the sample' do
      updated_status = described_class.find_latest_and_update!(sample, attributes: { status: 'processing' })
      expect(updated_status.status).to eq('processing')
    end

    it 'updates the most recent status for the sample filtered by status' do
      updated_status = described_class.find_latest_and_update!(sample, status: 'failed',
                                                                       attributes: { status: 'aborted' })
      expect(updated_status.status).to eq('aborted')
    end

    it 'raises an error if no status exists for the sample' do
      another_sample = create(:sample)
      expect do
        described_class.find_latest_and_update!(another_sample, attributes: { status: 'processing' })
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
