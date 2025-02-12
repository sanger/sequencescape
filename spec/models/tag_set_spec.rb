# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TagSet do
  describe 'validations' do
    it 'is valid with valid attributes' do
      tag_set = build(:tag_set)
      expect(tag_set).to be_valid
    end

    it 'is valid without a tag2_group' do
      tag_set = build(:tag_set, tag2_group: nil)
      expect(tag_set).to be_valid
    end

    it 'is valid when the tag groups have the same adapter type' do
      adapter_type = build(:adapter_type)
      tag_group = create(:tag_group, adapter_type:)
      tag_group2 = create(:tag_group, adapter_type:)
      tag_set = build(:tag_set, tag_group: tag_group, tag2_group: tag_group2)
      expect(tag_set).to be_valid
    end

    it 'is not valid without a name' do
      tag_set = build(:tag_set, name: nil)
      expect(tag_set).not_to be_valid
      expect(tag_set.errors[:name]).to include("can't be blank")
    end

    it 'is not valid when the name is not unique' do
      create(:tag_set, name: 'test name')
      tag_set2 = build(:tag_set, name: 'test name')
      expect(tag_set2).not_to be_valid
      expect(tag_set2.errors[:name]).to include('has already been taken')
    end

    it 'is not valid without a tag_group' do
      tag_set = build(:tag_set, tag_group: nil, tag2_group: nil)
      expect(tag_set).not_to be_valid
      expect(tag_set.errors[:tag_group]).to include('must exist')
    end

    it 'is not valid when the tag groups have different adapter types' do
      tag_group1 = create(:tag_group, adapter_type: build(:adapter_type))
      tag_group2 = create(:tag_group, adapter_type: build(:adapter_type))
      tag_set = build(:tag_set, tag_group: tag_group1, tag2_group: tag_group2)
      expect(tag_set).not_to be_valid
      expect(tag_set.errors[:tag_group]).to include('Adapter types of tag groups must match')
    end
  end

  describe 'scopes' do
    describe '.dual_index' do
      context 'when there are single index tag sets' do
        let!(:tag_set1) { create(:tag_set) }
        let!(:tag_set2) { create(:tag_set) }
        let!(:tag_set3) { create(:tag_set, tag2_group: nil) }

        it 'does not return single index tag sets' do
          expect(described_class.dual_index).not_to include(tag_set3)
        end

        it 'returns dual index tag sets' do
          expect(described_class.dual_index).to include(tag_set1, tag_set2)
        end
      end
    end

    describe '.dual_index.visible' do
      context 'when there are single and dual index tag sets, where not all tag groups are visible' do
        let!(:tag_group1) { create(:tag_group_with_tags, name: 'TG1') }
        let!(:tag_group2) { create(:tag_group_with_tags, name: 'TG2', visible: false) }
        let!(:tag_group3) { create(:tag_group_with_tags, name: 'TG3') }
        let!(:tag_group4) { create(:tag_group_with_tags, name: 'TG4') }
        let!(:tag_group5) { create(:tag_group_with_tags, name: 'TG5') }

        let!(:tag_set1) { create(:tag_set, tag_group: tag_group1, tag2_group: tag_group2) }
        let!(:tag_set2) { create(:tag_set, tag_group: tag_group3, tag2_group: tag_group4) }
        let!(:tag_set3) { create(:tag_set, tag_group: tag_group5, tag2_group: nil) }

        it 'does not return single or dual index tag sets with non visible tag groups' do
          expect(described_class.dual_index.visible).not_to include(tag_set1, tag_set3)
        end

        it 'returns dual index tag sets with visible tag groups only' do
          expect(described_class.dual_index.visible).to include(tag_set2)
        end
      end
    end

    describe '.single_index' do
      context 'when there are dual index tag sets' do
        let!(:tag_set1) { create(:tag_set, tag2_group: nil) }
        let!(:tag_set2) { create(:tag_set, tag2_group: nil) }
        let!(:tag_set3) { create(:tag_set) }

        it 'does not return single index tag sets' do
          expect(described_class.single_index).not_to include(tag_set3)
        end

        it 'returns single index tag sets' do
          expect(described_class.single_index).to include(tag_set1, tag_set2)
        end
      end
    end
  end

  describe '.single_index.visible' do
    context 'when there are single and dual index tag sets, where not all tag groups are visible' do
      let!(:tag_group1) { create(:tag_group_with_tags, name: 'TG1', visible: false) }
      let!(:tag_group2) { create(:tag_group_with_tags, name: 'TG2') }
      let!(:tag_group3) { create(:tag_group_with_tags, name: 'TG3') }
      let!(:tag_group4) { create(:tag_group_with_tags, name: 'TG4') }

      let!(:tag_set1) { create(:tag_set, tag_group: tag_group1, tag2_group: nil) }
      let!(:tag_set2) { create(:tag_set, tag_group: tag_group2, tag2_group: nil) }
      let!(:tag_set3) { create(:tag_set, tag_group: tag_group3, tag2_group: tag_group4) }

      it 'does not return single or dual index tag sets with non visible tag groups' do
        expect(described_class.single_index.visible).not_to include(tag_set1, tag_set3)
      end

      it 'returns single index tag sets with visible tag groups only' do
        expect(described_class.single_index.visible).to include(tag_set2)
      end
    end
  end

  describe '#visible' do
    it 'returns true if it only has one tag_group and it is set to visible' do
      tag_group = create(:tag_group, visible: true)
      tag_set = create(:tag_set, tag_group: tag_group, tag2_group: nil)
      expect(tag_set.visible).to be(true)
    end

    it 'returns false if it only has one tag_group and it is not set to visible' do
      tag_group = create(:tag_group, visible: false)
      tag_set = create(:tag_set, tag_group: tag_group, tag2_group: nil)
      expect(tag_set.visible).to be(false)
    end

    it 'returns true if both tag_groups are set to visible' do
      tag_group = create_list(:tag_group, 2, visible: true)
      tag_set = create(:tag_set, tag_group: tag_group[0], tag2_group: tag_group[1])
      expect(tag_set.visible).to be(true)
    end

    it 'returns false if one of the tag_groups is not set to visible' do
      tag_group = create(:tag_group, visible: true)
      tag_group2 = create(:tag_group, visible: false)
      tag_set = create(:tag_set, tag_group: tag_group, tag2_group: tag_group2)
      expect(tag_set.visible).to be(false)
    end
  end

  describe('visible_single_index_chromium') do
    let!(:non_chromium_adapter_type) { create(:adapter_type, name: 'test_adapter') }
    let!(:chromium_adapter_type) { create(:adapter_type, name: 'Chromium') }
    let!(:tag_group1) { create(:tag_group, adapter_type: chromium_adapter_type) }
    let!(:tag_group2) { create(:tag_group, adapter_type: chromium_adapter_type, visible: false) }
    let!(:tag_group3) { create(:tag_group, adapter_type: non_chromium_adapter_type) }
    let!(:tag_group4) { create(:tag_group, adapter_type: non_chromium_adapter_type) }
    let!(:tag_group5) { create(:tag_group, adapter_type: non_chromium_adapter_type) }
    let!(:tag_set1) { create(:tag_set, tag_group: tag_group1, tag2_group: nil) }
    let(:tag_set2) { create(:tag_set, tag_group: tag_group2, tag2_group: nil) }
    let!(:tag_set3) { create(:tag_set, tag_group: tag_group3, tag2_group: nil) }
    let!(:tag_set4) { create(:tag_set, tag_group: tag_group4, tag2_group: tag_group5) }

    it 'excludes non-chromium or non-visible tag groups and dual index tag sets' do
      expect(described_class.visible_single_index_chromium).not_to include(tag_set2, tag_set3, tag_set4)
    end

    it 'returns single index tag sets with chromium tag groups' do
      expect(described_class.visible_single_index_chromium).to include(tag_set1)
    end
  end

  describe '#adapter_type' do
    it 'delegates to tag_group' do
      tag_group = create(:tag_group)
      tag_set = create(:tag_set, tag_group: tag_group, tag2_group: nil)
      expect(tag_set.adapter_type).to eq(tag_group.adapter_type)
    end
  end

  describe '#tag_group_name=' do
    it 'sets the tag_group' do
      tag_group = create(:tag_group)
      tag_set = build(:tag_set)
      tag_set.tag_group_name = tag_group.name
      expect(tag_set.tag_group).to eq(tag_group)
    end

    it 'raises an error if the tag_group does not exist' do
      tag_set = build(:tag_set)
      expect { tag_set.tag_group_name = 'non-existent tag group' }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#tag2_group_name=' do
    it 'sets the tag_group' do
      tag_group = create(:tag_group)
      tag_set = build(:tag_set)
      tag_set.tag2_group_name = tag_group.name
      expect(tag_set.tag2_group).to eq(tag_group)
    end

    it 'raises an error if the tag_group does not exist' do
      tag_set = build(:tag_set)
      expect { tag_set.tag2_group_name = 'non-existent tag group' }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#tag_groups_within_visible_single_index_chromium' do
    context 'when there are single and dual index tag sets, where not all tag groups are visible' do
      let(:non_chromium_adapter_type) { create(:adapter_type, name: 'test_adapter') }
      let(:chromium_adapter_type) { create(:adapter_type, name: 'Chromium') }
      let(:tag_group1) { create(:tag_group, adapter_type: chromium_adapter_type) }
      let(:tag_group2) { create(:tag_group, adapter_type: chromium_adapter_type, visible: false) }
      let(:tag_group3) { create(:tag_group, adapter_type: non_chromium_adapter_type) }
      let(:tag_group4) { create(:tag_group, adapter_type: non_chromium_adapter_type) }
      let(:tag_group5) { create(:tag_group, adapter_type: non_chromium_adapter_type) }
      let(:tag_set1) { create(:tag_set, tag_group: tag_group1, tag2_group: nil) }
      let(:tag_set2) { create(:tag_set, tag_group: tag_group2, tag2_group: nil) }
      let(:tag_set3) { create(:tag_set, tag_group: tag_group3, tag2_group: nil) }
      let(:tag_set4) { create(:tag_set, tag_group: tag_group4, tag2_group: tag_group5) }

      before do
        tag_group1
        tag_group2
        tag_group3
        tag_group4
        tag_group5
        tag_set1
        tag_set2
        tag_set3
        tag_set4
      end

      def expect_not_to_include_non_visible_tag_sets
        expect(described_class.visible_single_index_chromium).not_to include(tag_set2, tag_set3, tag_set4)
      end
      it 'does not return tag groups belong to single or dual index tag sets with non visible' do
        expect_not_to_include_non_visible_tag_sets
      end

      it 'returns all tag groups with visible tag groups only' do
        expect(described_class.tag_groups_within_visible_single_index_chromium).to include(tag_group1)
      end
    end
  end
end
