require 'rails_helper'
require 'shared_contexts/limber_shared_context'

# Note: These tests JUST check the factory characteristic of layout
# templates. The actual layout of tags is carried out by the tag layouts themselves,
# and is tested there.
describe TagLayoutTemplate do
  let(:template) do
    build :tag_layout_template,
          direction_algorithm: direction_algorithm,
          walking_algorithm: walking_algorithm,
          tag2_group: tag2_group
  end

  describe '#create!' do
    let(:user) { build :user }
    subject { template.create!(plate: plate, user: user) }
    let(:plate) { create :plate }
    let(:tag2_group) { nil }

    context 'by plate in columns' do
      let(:direction_algorithm) { 'TagLayout::InColumns' }
      let(:walking_algorithm) { 'TagLayout::WalkWellsOfPlate' }
      it { is_expected.to be_a TagLayout }

      it 'passes in the correct properties' do
        expect(subject.plate).to eq(plate)
        expect(subject.direction).to eq('column')
        expect(subject.walking_by).to eq('wells of plate')
        expect(tag2_group).to eq(tag2_group)
      end

      context 'with a tag2 group' do
        it { is_expected.to be_a TagLayout }
        let(:tag2_group) { create :tag_group }
        it 'passes in the correct properties' do
          expect(subject.plate).to eq(plate)
          expect(subject.tag2_group).to eq(tag2_group)
        end
      end
    end

    context 'by pool in rows' do
      let(:direction_algorithm) { 'TagLayout::InRows' }
      let(:walking_algorithm) { 'TagLayout::WalkWellsByPools' }
      it { is_expected.to be_a TagLayout }

      it 'passes in the correct properties' do
        expect(subject.plate).to eq(plate)
        expect(subject.direction).to eq('row')
        expect(subject.walking_by).to eq('wells in pools')
      end
    end
  end
end
