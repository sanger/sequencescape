# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Submission, type: :model do
  describe '#priority' do
    let(:submission) { described_class.new(user: create(:user)) }

    it 'be 0 by default' do
      expect(submission.priority).to eq 0
    end

    it 'be changable' do
      submission.priority = 3
      expect(submission).to be_valid
      expect(submission.priority).to eq 3
    end

    it 'have a maximum of 3' do
      submission.priority = 4
      expect(submission).not_to be_valid
    end
  end

  describe '#orders' do
    let!(:request_type_1) { create(:request_type) }
    let!(:request_type_2) { create(:request_type) }
    let!(:request_type_3) { create(:request_type) }
    let!(:request_type_4) { create(:request_type) }
    let!(:request_type_for_multiplexing) { create(:request_type, for_multiplexing: true) }

    it 'are compatible if all request types after multiplexing requests are the same and all read lengths are the same' do
      request_types = [request_type_1.id, request_type_2.id, request_type_for_multiplexing.id, request_type_3.id, request_type_4.id]
      order1 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      order2 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      order3 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      order4 = create(:order, request_types: [request_type_1.id] + request_types, request_options: { read_length: 100 })
      expect(build(:submission, orders: [order1, order2, order3, order4])).to be_valid
    end

    it 'are compatible if there are no request types for multiplexing' do
      order1 = create(:order, request_types: [request_type_1.id, request_type_2.id], request_options: { read_length: 100 })
      order2 = create(:order, request_types: [request_type_3.id, request_type_1.id, request_type_4.id], request_options: { read_length: 100 })
      order3 = create(:order, request_types: [request_type_1.id], request_options: { read_length: 100 })
      order4 = create(:order, request_types: [request_type_4.id, request_type_3.id], request_options: { read_length: 100 })
      expect(build(:submission, orders: [order1, order2, order3, order4])).to be_valid
    end

    it 'are not compatible with different request types after a multiplexed request types' do
      request_types = [request_type_1.id, request_type_2.id, request_type_for_multiplexing.id, request_type_3.id]
      order1 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      order2 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      order3 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      request_types[3] = request_type_4.id
      order4 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      expect(build(:submission, orders: [order1, order2, order3, order4])).not_to be_valid
    end

    it 'are not compatible if any of the read lengths are different' do
      request_types = [request_type_1.id, request_type_2.id, request_type_for_multiplexing.id, request_type_3.id]
      order1 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      order2 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      order3 = create(:order, request_types: request_types, request_options: { read_length: 200 })
      order4 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      expect(build(:submission, orders: [order1, order2, order3, order4])).not_to be_valid
    end

    it 'are not compatible if at least one of the request types are not for multiplexing' do
      request_types = [request_type_1.id, request_type_2.id, request_type_for_multiplexing.id, request_type_3.id]
      order1 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      order2 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      order3 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      request_types = [request_type_1.id, request_type_2.id, request_type_3.id, request_type_4.id]
      order4 = create(:order, request_types: request_types, request_options: { read_length: 100 })
      expect(build(:submission, orders: [order1, order2, order3, order4])).not_to be_valid
    end
  end

  it 'knows all samples that can not be included in submission' do
    sample_manifest = create :tube_sample_manifest_with_samples
    sample_manifest.samples.first.sample_metadata.update(supplier_name: 'new_name')
    samples = sample_manifest.samples[1..-1]
    order1 = create :order, assets: sample_manifest.labware

    asset = create :sample_tube
    order2 = create :order, assets: [asset.receptacle]

    submission = described_class.new(user: create(:user), orders: [order1, order2])

    expect(submission.not_ready_samples).to eq samples
  end

  describe '#used_tags' do
    let(:submission) { create :submission }
    let(:request_1) { create :request, submission: submission }
    let(:request_2) { create :request, submission: submission }
    let(:tag_a) { create :tag }
    let(:tag2_a) { create :tag }
    let(:tag_b) { create :tag }
    let(:tag2_b) { create :tag }

    before do
      # Some untagged aliquots upstream of tagging
      create :untagged_aliquot, request: request_1
      create :untagged_aliquot, request: request_2
      # Once tagged, we may have multiple tagged aliquots
      create :aliquot, request: request_1, tag: tag_a, tag2: tag2_a
      create :aliquot, request: request_2, tag: tag_b, tag2: tag2_b
      create :aliquot, request: request_1, tag: tag_a, tag2: tag2_a
      create :aliquot, request: request_2, tag: tag_b, tag2: tag2_b
    end

    it 'returns an array of used tag pairs' do
      expect(submission.used_tags).to eq([[tag_a.oligo, tag2_a.oligo], [tag_b.oligo, tag2_b.oligo]])
    end
  end
end
