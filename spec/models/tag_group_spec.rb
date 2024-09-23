# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TagGroup do
  context 'when the name is not unique' do
    let(:tag_group_1) { create(:tag_group, tag_count: 3, name: 'test name') }
    let(:tag_group_2) { build(:tag_group, tag_count: 3, name: 'test name') }

    it 'is not a valid model' do
      tag_group_1
      expect(tag_group_2).not_to be_valid
    end
  end

  context 'when the tags are sorted' do
    let(:tag_group_1) { create(:tag_group) }
    let(:tag_1) { create(:tag, map_id: 1, tag_group: tag_group_1) }
    let(:tag_2) { create(:tag, map_id: 4, tag_group: tag_group_1) }
    let(:tag_3) { create(:tag, map_id: 2, tag_group: tag_group_1) }
    let(:tag_4) { create(:tag, map_id: 3, tag_group: tag_group_1) }

    context 'by map id' do
      it 'returns the tags in the correct order' do
        tag_group_1.tags << tag_1 << tag_2 << tag_3 << tag_4
        expect(tag_group_1.tags_sorted_by_map_id).to eq([tag_1, tag_3, tag_4, tag_2])
      end
    end

    context 'by index' do
      it 'returns the tags in the correct order' do
        tag_group_1.tags << tag_1 << tag_2 << tag_3 << tag_4
        expect(tag_group_1.indexed_tags).to eq(1 => tag_1.oligo, 2 => tag_3.oligo, 3 => tag_4.oligo, 4 => tag_2.oligo)
      end
    end
  end

  context 'when the tag group is not visible' do
    let!(:tag_group_1) { create(:tag_group_with_tags, name: 'TG1') }
    let!(:tag_group_2) { create(:tag_group_with_tags, name: 'TG2', visible: false) }
    let!(:tag_group_3) { create(:tag_group_with_tags, name: 'TG3') }

    it 'is not selectable by the visible scope' do
      expect(described_class.visible).not_to include(tag_group_2)
    end

    it 'remaining tag groups should be selectable by the visible scope' do
      expect(described_class.visible).to include(tag_group_1, tag_group_3)
    end
  end

  describe '#adapter_type_name' do
    subject { tag_group.adapter_type_name }

    let(:tag_group) { build_stubbed :tag_group, adapter_type: }

    context 'when an adapter type is specified' do
      let(:adapter_type) { build_stubbed :adapter_type, name: 'name' }

      it { is_expected.to eq 'name' }
    end

    context 'when an adapter type is unspecified' do
      let(:adapter_type) { nil }

      it { is_expected.to eq 'Unspecified' }
    end
  end

  describe '#by_adaptor_type' do
    let!(:adapter_type) { create(:adapter_type, name: 'test_adapter') }
    let!(:tag_group) { create(:tag_group, adapter_type:) }

    context 'a tag group' do
      it 'is selected when the scope adapter name matches' do
        expect(described_class.by_adapter_type('test_adapter')).to include(tag_group)
      end

      it 'is not selected when the scope adaptor name does not match' do
        expect(described_class.by_adapter_type('another_test_adapter')).not_to include(tag_group)
      end
    end
  end
end
