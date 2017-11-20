require 'rails_helper'

RSpec.describe Aliquot, type: :model do
  let(:tag1) { create :tag }
  let(:tag2) { create :tag }
  let(:sample1) { create :sample }
  let(:sample2) { create :sample }

  shared_context 'a tag matcher' do
    context 'with the same tags' do
      let(:aliquot1) { build :aliquot, tag: tag1, tag2: tag1, sample: sample1 }
      let(:aliquot2) { build :aliquot, tag: tag1, tag2: tag1, sample: sample1 }
      it { is_expected.to be true }
    end

    context 'with different tags' do
      let(:aliquot1) { build :aliquot, tag: tag1, tag2: tag1, sample: sample1 }
      let(:aliquot2) { build :aliquot, tag: tag2, tag2: tag1, sample: sample1 }
      it { is_expected.to be false }
    end

    context 'with different tag 2' do
      let(:aliquot1) { build :aliquot, tag: tag1, tag2: tag1, sample: sample1 }
      let(:aliquot2) { build :aliquot, tag: tag1, tag2: tag2, sample: sample1 }
      it { is_expected.to be false }
    end

    context 'with missing tags' do
      let(:aliquot1) { build :aliquot, tag: tag1, tag2_id: -1, sample: sample1 }
      let(:aliquot2) { build :aliquot, tag: nil,  tag2_id: -1, sample: sample1 }
      it { is_expected.to be true }
    end

    context 'with missing tag 2' do
      let(:aliquot1) { build :aliquot, tag: nil, tag2: tag1, sample: sample1 }
      let(:aliquot2) { build :aliquot, tag: nil, tag2_id: -1, sample: sample1 }
      it { is_expected.to be true }
    end

    context 'with missing tags but present tag 2s' do
      let(:aliquot1) { build :aliquot, tag: tag1, tag2: tag1, sample: sample1 }
      let(:aliquot2) { build :aliquot, tag: nil,  tag2: tag1, sample: sample1 }
      it { is_expected.to be true }
    end

    context 'with missing tag 2s but present tags' do
      let(:aliquot1) { build :aliquot, tag: tag1, tag2: tag1, sample: sample1 }
      let(:aliquot2) { build :aliquot, tag: tag1, tag2_id: -1, sample: sample1 }
      it { is_expected.to be true }
    end

    context 'with different samples' do
      let(:aliquot1) { build :aliquot, tag: tag1, tag2: tag1, sample: sample1 }
      let(:aliquot2) { build :aliquot, tag: tag1, tag2: tag1, sample: sample2 }
      it { is_expected.to be false }
    end
  end

  describe '#matches?' do
    # Matches is a stricter matcher than #=~
    subject { aliquot1.matches?(aliquot2) }
    it_behaves_like 'a tag matcher'
  end

  describe '#=~' do
    subject { aliquot1 =~ aliquot2 }
    it_behaves_like 'a tag matcher'
  end

  context 'mixing tests' do
    let(:asset) { create :empty_well }

    it 'allows mixing different tags with no tag2' do
      asset.aliquots << build(:aliquot, tag: tag1, sample: sample1) << build(:aliquot, tag: tag2, sample: sample2)
      expect(asset.save).to be true
    end

    it 'allows mixing different tags with a tag 2' do
      asset.aliquots << build(:aliquot, tag: tag1, tag2: tag1, sample: sample1) << build(:aliquot, tag: tag2, tag2: tag1, sample: sample2)
      expect(asset.save).to be true
    end

    it 'allows mixing same tags with a different tag 2' do
      asset.aliquots << build(:aliquot, tag: tag1, tag2: tag1, sample: sample1) << build(:aliquot, tag: tag1, tag2: tag2, sample: sample2)
      expect(asset.save).to be true
    end
  end

  describe '#set_library' do
    let(:receptacle) { create :empty_well }
    subject { build :aliquot, receptacle: receptacle, library_id: initial_library_id }

    before(:each) do
      subject.set_library
    end

    context 'when not set' do
      let(:initial_library_id) { nil }

      it 'gets set to the receptacle id' do
        expect(subject.library_id).to eq(receptacle.id)
      end
    end

    context 'when previously set' do
      let(:initial_library_id) { create(:empty_well).id }

      it 'gets set to the receptacle id' do
        expect(subject.library_id).to eq(receptacle.id)
      end
    end
  end

  describe 'for tags substitution' do
    it 'should generate correct substitution hash' do
      aliquot = create :aliquot
      tag_id = aliquot.tag_id
      expect(aliquot.substitution_hash).to be nil
      aliquot.update_attributes!(tag_id: Tag.first.id, insert_size_from: 5, insert_size_to: 15)
      expect(aliquot.other_attributes_for_substitution).to eq('insert_size_from' => 5, 'insert_size_to' => 15)
      expect(aliquot.substitution_hash).to eq(sample_id: aliquot.sample_id, library_id: aliquot.library_id, original_tag_id: tag_id, substitute_tag_id: Tag.first.id, 'insert_size_from' => 5, 'insert_size_to' => 15)
    end
  end

  it 'provides number of aliquots by cost code' do
    aliquots = create_list(:aliquot, 5)
    aliquots.first.update_attributes!(project: nil)
    aliquots.second.project.project_metadata.update_attributes!(project_cost_code: 'new_cost_code')
    default_project_cost_code = aliquots.last.project.project_metadata.project_cost_code
    receptacle = create :empty_well
    receptacle.aliquots << aliquots
    expect(receptacle.aliquots.count_by_project_cost_code).to eq('new_cost_code' => 1, default_project_cost_code => 3, nil => 1)
  end
end
