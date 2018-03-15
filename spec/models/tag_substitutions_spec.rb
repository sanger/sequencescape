# frozen_string_literal: true

require 'rails_helper'

describe TagSubstitution do
  # Works for: Library manifests, old tube pipelines
  # We have two samples, each with unique tags, which only exist
  # in aliquots identified by the library id. We don't need to consider:
  # - Tagged aliquots without a library id (eg. External pipeline apps)
  # - Multiple tags for the same sample/library (Chromium pipelines)
  # - Introducing invalid state through persisting tag clashes. (Theoretically any pipline, but esp. Generic Lims QC pools)
  # Note: The tag swap scenario used here is important, as a naive approach results in a temporary tag clash. If you make
  # changes to this suite, please ensure this scenario is still tested.

  let(:sample_a) { create :sample }
  let(:sample_b) { create :sample }
  let(:library_tube_a) { create :library_tube }
  let(:library_tube_b) { create :library_tube }
  let(:mx_library_tube) { create :multiplexed_library_tube }
  let(:library_type) { create :library_type }

  subject { TagSubstitution.new(instructions) }

  context 'with a simple tag swap' do
    let(:sample_a_orig_tag) { create :tag }
    let(:sample_a_orig_tag2) { create :tag }
    let(:sample_b_orig_tag) { create :tag }
    let(:sample_b_orig_tag2) { create :tag }

    let!(:library_aliquot_a) { create :aliquot, sample: sample_a, tag: sample_a_orig_tag, tag2: sample_a_orig_tag2, library: library_tube_a, receptacle: library_tube_a }
    let!(:library_aliquot_b) { create :aliquot, sample: sample_b, tag: sample_b_orig_tag, tag2: sample_b_orig_tag2, library: library_tube_b, receptacle: library_tube_b }
    let!(:mx_aliquot_a) { create :aliquot, sample: sample_a, tag: sample_a_orig_tag, tag2: sample_a_orig_tag2, library: library_tube_a, receptacle: mx_library_tube }
    let!(:mx_aliquot_b) { create :aliquot, sample: sample_b, tag: sample_b_orig_tag, tag2: sample_b_orig_tag2, library: library_tube_b, receptacle: mx_library_tube }

    context 'with only tag 1' do
      let(:instructions) do
        [
          { sample_id: sample_a.id, library_id: library_tube_a.id, original_tag_id: sample_a_orig_tag.id, substitute_tag_id: sample_b_orig_tag.id },
          { sample_id: sample_b.id, library_id: library_tube_b.id, original_tag_id: sample_b_orig_tag.id, substitute_tag_id: sample_a_orig_tag.id }
        ]
      end

      it 'perform the correct tag substitutions' do
        assert subject.save, "TagSubstitution did not save. #{subject.errors.full_messages}"
        expect(library_aliquot_a.reload.tag).to eq sample_b_orig_tag
        expect(library_aliquot_b.reload.tag).to eq sample_a_orig_tag
        expect(mx_aliquot_a.reload.tag).to eq sample_b_orig_tag
        expect(mx_aliquot_b.reload.tag).to eq sample_a_orig_tag
      end
    end

    context 'with tag2s defined' do
      let(:instructions) do
        [
          { sample_id: sample_a.id, library_id: library_tube_a.id, original_tag_id: sample_a_orig_tag.id, substitute_tag_id: sample_b_orig_tag.id, original_tag2_id: sample_a_orig_tag2.id, substitute_tag2_id: sample_b_orig_tag2.id },
          { sample_id: sample_b.id, library_id: library_tube_b.id, original_tag_id: sample_b_orig_tag.id, substitute_tag_id: sample_a_orig_tag.id, original_tag2_id: sample_b_orig_tag2.id, substitute_tag2_id: sample_a_orig_tag2.id }
        ]
      end

      it 'perform the correct tag2 substitutions' do
        assert subject.save, "TagSubstitution did not save. #{subject.errors.full_messages}"
        expect(library_aliquot_a.reload.tag).to eq sample_b_orig_tag
        expect(library_aliquot_b.reload.tag).to eq sample_a_orig_tag
        expect(mx_aliquot_a.reload.tag).to eq sample_b_orig_tag
        expect(mx_aliquot_b.reload.tag).to eq sample_a_orig_tag
        expect(library_aliquot_a.reload.tag2).to eq sample_b_orig_tag2
        expect(library_aliquot_b.reload.tag2).to eq sample_a_orig_tag2
        expect(mx_aliquot_a.reload.tag2).to eq sample_b_orig_tag2
        expect(mx_aliquot_b.reload.tag2).to eq sample_a_orig_tag2
      end
    end

    context 'when details don\'t match' do
      let(:instructions) do
        [
          { sample_id: sample_a.id, library_id: library_tube_a.id, original_tag_id: sample_b_orig_tag.id, substitute_tag_id: sample_a_orig_tag.id, original_tag2_id: sample_a_orig_tag2.id, substitute_tag2_id: sample_b_orig_tag2.id },
          { sample_id: sample_b.id, library_id: library_tube_b.id, original_tag_id: sample_a_orig_tag.id, substitute_tag_id: sample_b_orig_tag.id, original_tag2_id: sample_b_orig_tag2.id, substitute_tag2_id: sample_a_orig_tag2.id }
        ]
      end

      it 'return false and an error of the details don\'t match' do
        refute subject.save, 'Substitution saved when it should have errord'
        assert_includes subject.errors.full_messages, 'Substitution Matching aliquots could not be found'
      end
    end

    context 'when other attributes are updated' do
      let(:instructions) do
        [
          { sample_id: sample_a.id, library_id: library_tube_a.id, original_tag_id: sample_a_orig_tag.id, substitute_tag_id: sample_a_orig_tag.id, library_type: library_type.name, insert_size_from: 20, insert_size_to: 400 },
          { sample_id: sample_b.id, library_id: library_tube_b.id, original_tag_id: sample_b_orig_tag.id, substitute_tag_id: sample_b_orig_tag.id, library_type: library_type.name, insert_size_from: 20, insert_size_to: 400 }
        ]
      end

      it 'also update allow update of other attributes' do
        assert subject.save, "TagSubstitution did not save. #{subject.errors.full_messages}"

        [library_aliquot_a, library_aliquot_b, mx_aliquot_a, mx_aliquot_b].each do |aliquot|
          aliquot.reload
          assert_equal aliquot.library_type, library_type.name
          assert_equal 20, aliquot.insert_size_from
          assert_equal 400, aliquot.insert_size_to
        end
      end
    end
  end

  context 'with a multi-tag sample tag swap' do
    let(:sample_a_orig_tag_a) { create :tag }
    let(:sample_b_orig_tag_a) { create :tag }
    let(:sample_a_orig_tag_b) { create :tag }
    let(:sample_b_orig_tag_b) { create :tag }
    let(:other_tag) { create :tag }

    let(:instructions) do
      [
        { sample_id: sample_a.id, library_id: library_tube_a.id, original_tag_id: sample_a_orig_tag_a.id, substitute_tag_id: sample_b_orig_tag_a.id },
        { sample_id: sample_a.id, library_id: library_tube_a.id, original_tag_id: sample_a_orig_tag_b.id, substitute_tag_id: other_tag.id },
        { sample_id: sample_b.id, library_id: library_tube_b.id, original_tag_id: sample_b_orig_tag_a.id, substitute_tag_id: sample_a_orig_tag_a.id }
      ]
    end

    let!(:library_aliquot_a_a) { create :aliquot, sample: sample_a, tag: sample_a_orig_tag_a, library: library_tube_a, receptacle: library_tube_a }
    let!(:library_aliquot_a_b) { create :aliquot, sample: sample_a, tag: sample_a_orig_tag_b, library: library_tube_a, receptacle: library_tube_a }

    let!(:library_aliquot_b_a) { create :aliquot, sample: sample_b, tag: sample_b_orig_tag_a, library: library_tube_b, receptacle: library_tube_b }
    let!(:library_aliquot_b_b) { create :aliquot, sample: sample_b, tag: sample_b_orig_tag_b, library: library_tube_b, receptacle: library_tube_b }

    let!(:mx_aliquot_a_a) { create :aliquot, sample: sample_a, tag: sample_a_orig_tag_a, library: library_tube_a, receptacle: mx_library_tube }
    let!(:mx_aliquot_a_b) { create :aliquot, sample: sample_a, tag: sample_a_orig_tag_b, library: library_tube_a, receptacle: mx_library_tube }
    let!(:mx_aliquot_b_a) { create :aliquot, sample: sample_b, tag: sample_b_orig_tag_a, library: library_tube_b, receptacle: mx_library_tube }
    let!(:mx_aliquot_b_b) { create :aliquot, sample: sample_b, tag: sample_b_orig_tag_b, library: library_tube_b, receptacle: mx_library_tube }

    it 'perform the correct substitutions' do
      assert subject.save, "TagSubstitution did not save. #{subject.errors.full_messages}"
      expect(library_aliquot_a_a.reload.tag).to eq sample_b_orig_tag_a
      expect(library_aliquot_b_a.reload.tag).to eq sample_a_orig_tag_a
      expect(mx_aliquot_a_a.reload.tag).to eq sample_b_orig_tag_a
      expect(mx_aliquot_b_a.reload.tag).to eq sample_a_orig_tag_a

      expect(library_aliquot_a_b.reload.tag).to eq other_tag
      expect(library_aliquot_b_b.reload.tag).to eq sample_b_orig_tag_b
      expect(mx_aliquot_a_b.reload.tag).to eq other_tag
      expect(mx_aliquot_b_b.reload.tag).to eq sample_b_orig_tag_b
    end
  end
end
