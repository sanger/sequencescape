# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/limber_shared_context'

RSpec.describe BroadcastEvent::LibraryComplete, broadcast_event: true do
  include_context 'a limber target plate with submissions'

  let(:user) { create(:user) }
  let(:work_completion) { WorkCompletion.create!(user: user, target: target_plate, submissions: [target_submission]) }
  let(:event) { described_class.create!(seed: work_completion, user: user, properties: { order_id: order.id }) }
  let(:subject_hash) { event.as_json['event'][:subjects].group_by(&:role_type) }
  let(:metadata) { event.as_json['event'][:metadata] }

  it 'generates a json' do
    expect(event.to_json).not_to be_nil
  end

  describe 'subjects' do
    it 'has an order' do
      expect(subject_hash['order'].count).to eq(1)
    end

    it 'has a study' do
      expect(subject_hash['study'].count).to eq(1)
    end

    it 'has a project' do
      expect(subject_hash['project'].count).to eq(1)
    end

    it 'has a submission' do
      expect(subject_hash['submission'].count).to eq(1)
    end

    it 'has 3 samples' do
      expect(subject_hash['sample'].count).to eq(3)
    end
  end

  describe 'metadata' do
    it 'has a library_type' do
      expect(metadata['library_type']).not_to be_nil
    end

    it 'has a fragment_size_from' do
      expect(metadata['fragment_size_from']).not_to be_nil
    end

    it 'has a fragment_size_to' do
      expect(metadata['fragment_size_to']).not_to be_nil
    end

    it 'has a bait_library' do
      expect(metadata['bait_library']).not_to be_nil
    end

    it 'has a order_type' do
      expect(metadata['order_type']).not_to be_nil
      expect(metadata['order_type']).not_to eq('UNKNOWN')
    end

    it 'has a submission_template' do
      expect(metadata['submission_template']).not_to be_nil
    end

    it 'has a team' do
      expect(metadata['team']).not_to be_nil
      expect(metadata['team']).not_to eq('UNKNOWN')
    end
  end
end
