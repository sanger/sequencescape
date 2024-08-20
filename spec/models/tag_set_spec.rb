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
      tag_group = create(:tag_group, adapter_type: adapter_type)
      tag_group2 = create(:tag_group, adapter_type: adapter_type)
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
end
