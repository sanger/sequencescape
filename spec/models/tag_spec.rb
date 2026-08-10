# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tag do
  describe 'validations' do
    it 'is valid with valid attributes' do
      tag = build(:tag)
      expect(tag).to be_valid
    end

    it 'is valid without a tag_group' do
      tag = build(:tag, tag_group: nil)
      expect(tag).to be_valid
    end

    it 'is valid when oligo is blank' do
      tag = build(:tag, oligo: nil)
      expect(tag).to be_valid
    end
  end

  describe 'scopes' do
    describe '.sorted' do
      it 'returns tags sorted by map_id' do
        tag1 = create(:tag, map_id: 2)
        tag2 = create(:tag, map_id: 1)
        expect(described_class.sorted).to eq([tag2, tag1])
      end
    end
  end

  describe 'methods' do
    describe '#name' do
      it 'returns the name of the tag' do
        tag = build(:tag, map_id: 1)
        expect(tag.name).to eq('Tag 1')
      end
    end

    describe '#summary' do
      it 'returns a hash with tag_group name and tag_index' do
        tag_group = create(:tag_group, name: 'Test Group')
        tag = build(:tag, map_id: 1, tag_group: tag_group)
        expect(tag.summary).to eq({ tag_group: 'Test Group', tag_index: '1' })
      end
    end

    describe '#tag!' do
      it 'attaches the tag to the specified asset' do
        tag = create(:tag)
        tube = create(:sample_tube)
        tag.tag!(tube.receptacle)

        expect(tube.receptacle.tags).to include(tag)
      end
    end

    describe '#untag!' do
      it 'removes the tag from the first aliquot' do
        tag = create(:tag)
        tube = create(:sample_tube)
        tube.aliquots.first.update(tag:)

        expect { tube.untag! }.to change { tube.aliquots.first.reload.tag }.from(tag).to(nil)
      end

      it 'does nothing if there are no aliquots' do
        tube = create(:tube)

        expect { tube.untag! }.not_to raise_error
      end
    end
  end
end
