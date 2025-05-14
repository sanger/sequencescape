# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aliquot do
  let(:tag1) { create(:tag) }
  let(:tag2) { create(:tag) }
  let(:sample1) { create(:sample) }
  let(:sample2) { create(:sample) }

  shared_context 'a tag matcher' do
    context 'with the same tags' do
      let(:aliquot1) { build(:aliquot, tag: tag1, tag2: tag1, sample: sample1) }
      let(:aliquot2) { build(:aliquot, tag: tag1, tag2: tag1, sample: sample1) }

      it { is_expected.to be true }
    end

    context 'with different tags' do
      let(:aliquot1) { build(:aliquot, tag: tag1, tag2: tag1, sample: sample1) }
      let(:aliquot2) { build(:aliquot, tag: tag2, tag2: tag1, sample: sample1) }

      it { is_expected.to be false }
    end

    context 'with different tag 2' do
      let(:aliquot1) { build(:aliquot, tag: tag1, tag2: tag1, sample: sample1) }
      let(:aliquot2) { build(:aliquot, tag: tag1, tag2: tag2, sample: sample1) }

      it { is_expected.to be false }
    end

    context 'with missing tags' do
      let(:aliquot1) { build(:aliquot, tag: tag1, tag2_id: -1, sample: sample1) }
      let(:aliquot2) { build(:aliquot, tag: nil, tag2_id: -1, sample: sample1) }

      it { is_expected.to be true }
    end

    context 'with missing tag 2' do
      let(:aliquot1) { build(:aliquot, tag: nil, tag2: tag1, sample: sample1) }
      let(:aliquot2) { build(:aliquot, tag: nil, tag2_id: -1, sample: sample1) }

      it { is_expected.to be true }
    end

    context 'with missing tags but present tag 2s' do
      let(:aliquot1) { build(:aliquot, tag: tag1, tag2: tag1, sample: sample1) }
      let(:aliquot2) { build(:aliquot, tag: nil, tag2: tag1, sample: sample1) }

      it { is_expected.to be true }
    end

    context 'with missing tag 2s but present tags' do
      let(:aliquot1) { build(:aliquot, tag: tag1, tag2: tag1, sample: sample1) }
      let(:aliquot2) { build(:aliquot, tag: tag1, tag2_id: -1, sample: sample1) }

      it { is_expected.to be true }
    end

    context 'with different samples' do
      let(:aliquot1) { build(:aliquot, tag: tag1, tag2: tag1, sample: sample1) }
      let(:aliquot2) { build(:aliquot, tag: tag1, tag2: tag1, sample: sample2) }

      it { is_expected.to be false }
    end
  end

  describe '#matches?' do
    # Matches is a stricter matcher than #=~
    subject { aliquot1.matches?(aliquot2) }

    it_behaves_like 'a tag matcher'
  end

  context 'mixing tests' do
    let(:asset) { create(:empty_well) }

    it 'allows mixing different tags with no tag2' do
      asset.aliquots << build(:aliquot, tag: tag1, sample: sample1) << build(:aliquot, tag: tag2, sample: sample2)
      expect(asset.save).to be true
    end

    it 'allows mixing different tags with a tag 2' do
      asset.aliquots << build(:aliquot, tag: tag1, tag2: tag1, sample: sample1) <<
        build(:aliquot, tag: tag2, tag2: tag1, sample: sample2)
      expect(asset.save).to be true
    end

    it 'allows mixing same tags with a different tag 2' do
      asset.aliquots << build(:aliquot, tag: tag1, tag2: tag1, sample: sample1) <<
        build(:aliquot, tag: tag1, tag2: tag2, sample: sample2)
      expect(asset.save).to be true
    end
  end

  describe '#set_library' do
    subject { build(:aliquot, receptacle: receptacle, library_id: initial_library_id) }

    let(:receptacle) { create(:empty_well) }

    before { subject.set_library(force:) }

    context 'when not set' do
      let(:force) { false }
      let(:initial_library_id) { nil }

      it 'gets set to the receptacle id' do
        expect(subject.library_id).to eq(receptacle.id)
      end
    end

    context 'when previously set and forced' do
      let(:force) { true }
      let(:initial_library_id) { create(:empty_well).id }

      it 'gets set to the receptacle id' do
        expect(subject.library_id).to eq(receptacle.id)
      end
    end

    context 'when previously set and not forced' do
      let(:force) { false }
      let(:initial_library_id) { create(:empty_well).id }

      it 'gets set to the receptacle id' do
        expect(subject.library_id).to eq(initial_library_id)
      end
    end
  end

  describe 'for tags substitution' do
    it 'generates correct substitution hash' do
      aliquot = create(:aliquot)
      tag_id = aliquot.tag_id
      expect(aliquot.substitution_hash).to be_nil
      aliquot.update!(tag_id: 42, insert_size_from: 5, insert_size_to: 15)
      expect(aliquot.other_attributes_for_substitution).to eq('insert_size_from' => 5, 'insert_size_to' => 15)
      expect(aliquot.substitution_hash).to eq(
        :sample_id => aliquot.sample_id,
        :library_id => aliquot.library_id,
        :original_tag_id => tag_id,
        :substitute_tag_id => 42,
        'insert_size_from' => 5,
        'insert_size_to' => 15
      )
    end
  end

  it 'provides number of aliquots by cost code' do
    aliquots = create_list(:aliquot, 5)
    aliquots.first.update!(project: nil)
    aliquots.second.project.project_metadata.update!(project_cost_code: 'new_cost_code')
    default_project_cost_code = aliquots.last.project.project_metadata.project_cost_code
    receptacle = create(:empty_well)
    receptacle.aliquots << aliquots
    expect(receptacle.aliquots.count_by_project_cost_code).to eq(
      'new_cost_code' => 1,
      default_project_cost_code => 3,
      nil => 1
    )
  end

  describe '#equivalent?' do
    let(:aliquot1) { build(:aliquot, tag: tag1, tag2: tag2, sample: sample1) }
    let(:aliquot2) { build(:aliquot, tag: tag1, tag2: tag2, sample: sample1) }

    context 'when no custom attributes are provided' do
      it 'returns true for equivalent aliquots' do
        expect(aliquot1.equivalent?(aliquot2)).to be true
      end

      it 'returns false for non-equivalent aliquots' do
        aliquot2.sample = sample2
        expect(aliquot1.equivalent?(aliquot2)).to be false
      end
    end

    context 'when a custom list of attributes is provided' do
      it 'returns true if only the specified attributes match' do
        aliquot2.sample = sample2
        expect(aliquot1.equivalent?(aliquot2, %w[tag_id tag2_id])).to be true
      end

      it 'returns false if the specified attributes do not match' do
        aliquot2.tag = create(:tag)
        expect(aliquot1.equivalent?(aliquot2, %w[tag_id tag2_id])).to be false
      end
    end
  end
end
