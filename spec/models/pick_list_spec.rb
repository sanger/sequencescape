# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PickList, :pick_list do
  subject(:pick_list) { described_class.new(pick_attributes: picks, asynchronous:) }

  let(:wells) { create_list(:untagged_well, 2) }
  let(:asynchronous) { false }
  let(:picks) { wells.map { |well| { source_receptacle: well } } }
  let(:project) { create(:project) }

  before do
    rt = create(:cherrypick_request_type, key: 'cherrypick')
    create(:cherrypick_pipeline, request_type: rt)
  end

  describe '#valid?' do
    # We want a simple interface, that doesn't demand any options that are not
    # strictly required.
    context 'with wells pre-populates with study and project' do
      it { is_expected.to be_valid }
    end

    context 'when wells lack project information' do
      let(:wells) { create_list(:untagged_well, 2, project: nil) }

      it { is_expected.not_to be_valid }
    end

    context 'when wells lack project information but the pick provides it' do
      let(:wells) { create_list(:untagged_well, 2, project: nil) }
      let(:picks) { wells.map { |well| { source_receptacle: well, project: } } }

      it { is_expected.to be_valid }
    end
  end

  describe '#state' do
    before { pick_list.save }

    context 'when asynchronous is true' do
      let(:asynchronous) { true }

      it { expect(pick_list).to be_pending }
    end

    context 'when asynchronous is false' do
      let(:asynchronous) { false }

      it { expect(pick_list).to be_built }
    end
  end

  describe '.receptacles' do
    subject { pick_list.receptacles }

    context 'when asynchronous is true' do
      let(:asynchronous) { true }

      it { is_expected.to eq wells }
    end

    context 'when asynchronous is false' do
      let(:asynchronous) { false }

      it { is_expected.to eq wells }
    end
  end

  describe '#links' do
    subject { pick_list.links }

    before { pick_list.save }

    context 'when asynchronous is true' do
      let(:asynchronous) { true }

      it do
        expect(subject).to include(
          name: "Pick-list #{pick_list.id}",
          url: pick_list_url(pick_list, host: configatron.site_url)
        )
      end
    end

    context 'when asynchronous is false' do
      let(:asynchronous) { false }

      it do
        expect(subject).to include(
          name: "Batch #{Batch.last.id}",
          url: batch_url(Batch.last, host: configatron.site_url)
        )
      end
    end
  end
end
