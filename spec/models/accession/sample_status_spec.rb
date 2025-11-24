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

  describe '#mark_in_progress' do
    let(:sample_status) { described_class.create_for_sample(sample) }

    before do
      sample_status.mark_in_progress
    end

    it 'updates the status to processing' do
      expect(sample_status.status).to eq('processing')
    end
  end

  describe '#mark_failed' do
    let(:sample_status) { described_class.create_for_sample(sample) }

    before do
      sample_status.mark_failed('Something went wrong')
    end

    it 'updates the status to failed' do
      expect(sample_status.status).to eq('failed')
    end

    it 'sets the failure message' do
      expect(sample_status.message).to eq('Something went wrong')
    end
  end

  describe '#mark_aborted' do
    let(:sample_status) { described_class.create_for_sample(sample) }

    before do
      sample_status.mark_failed('Previous error message')
      sample_status.mark_aborted
    end

    it 'updates the status to aborted' do
      expect(sample_status.status).to eq('aborted')
    end

    it 'leaves the previous message as it was' do
      expect(sample_status.message).to eq('Previous error message')
    end
  end
end
