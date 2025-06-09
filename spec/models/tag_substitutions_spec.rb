# frozen_string_literal: true

require 'rails_helper'

describe TagSubstitution, :warren do
  # Works for: Library manifests, old tube pipelines
  # We have two samples, each with unique tags, which only exist
  # in aliquots identified by the library id. We don't need to consider:
  # - Tagged aliquots without a library id (eg. External pipeline apps)
  # - Multiple tags for the same sample/library (Chromium pipelines)
  # - Introducing invalid state through persisting tag clashes. (Theoretically any pipline, but esp. Generic Lims QC
  #   pools)
  # Note: The tag swap scenario used here is important, as a naive approach results in a temporary tag clash. If you
  # make changes to this suite, please ensure this scenario is still tested.

  subject { described_class.new({ substitutions: instructions }.merge(additional_parameters)) }

  let(:sample_a) { create(:sample) }
  let(:sample_b) { create(:sample) }
  let(:library_tube_a) { create(:library_tube) }
  let(:library_tube_b) { create(:library_tube) }
  let(:mx_library_tube) { create(:multiplexed_library_tube) }
  let(:library_type) { create(:library_type) }
  let(:additional_parameters) { {} }

  shared_examples 'tag substitution' do
    describe '#save' do
      before { assert subject.save, "TagSubstitution did not save. #{subject.errors.full_messages}" }

      it 'perform the correct tag substitutions' do
        expect(library_aliquot_a.reload.tag).to eq sample_a_new_tag
        expect(library_aliquot_b.reload.tag).to eq sample_b_new_tag
        expect(mx_aliquot_a.reload.tag).to eq sample_a_new_tag
        expect(mx_aliquot_b.reload.tag).to eq sample_b_new_tag
      end

      it 'perform the correct tag2 substitutions' do
        expect(library_aliquot_a.reload.tag2).to eq sample_a_new_tag2
        expect(library_aliquot_b.reload.tag2).to eq sample_b_new_tag2
        expect(mx_aliquot_a.reload.tag2).to eq sample_a_new_tag2
        expect(mx_aliquot_b.reload.tag2).to eq sample_b_new_tag2
      end

      it 'assigns comments to the lanes and tubes' do
        expect(library_tube_a.receptacle.comments.map(&:description)).to eq [comment]
        expect(library_tube_b.receptacle.comments.map(&:description)).to eq [comment]
        expect(mx_library_tube.receptacle.comments.map(&:description)).to eq [comment]
        expect(lane.comments.map(&:description)).to eq [comment]
      end
    end

    it 'rebroadcasts the flowcell' do
      expect { subject.save }.to change {
        Warren.handler.messages_matching("queue_broadcast.messenger.#{flowcell_message.id}")
      }.by(1)
    end
  end

  context 'with a simple tag swap' do
    let(:sample_a_orig_tag) { create(:tag) }
    let(:sample_a_orig_tag2) { create(:tag) }
    let(:sample_a_new_tag) { sample_b_orig_tag }

    let(:sample_b_orig_tag) { create(:tag) }
    let(:sample_b_orig_tag2) { create(:tag) }
    let(:sample_b_new_tag) { sample_a_orig_tag }

    let!(:library_aliquot_a) do
      create(
        :aliquot,
        sample: sample_a,
        tag: sample_a_orig_tag,
        tag2: sample_a_orig_tag2,
        library: library_tube_a,
        receptacle: library_tube_a
      )
    end
    let!(:library_aliquot_b) do
      create(
        :aliquot,
        sample: sample_b,
        tag: sample_b_orig_tag,
        tag2: sample_b_orig_tag2,
        library: library_tube_b,
        receptacle: library_tube_b
      )
    end
    let!(:mx_aliquot_a) do
      create(
        :aliquot,
        sample: sample_a,
        tag: sample_a_orig_tag,
        tag2: sample_a_orig_tag2,
        library: library_tube_a,
        receptacle: mx_library_tube
      )
    end
    let!(:mx_aliquot_b) do
      create(
        :aliquot,
        sample: sample_b,
        tag: sample_b_orig_tag,
        tag2: sample_b_orig_tag2,
        library: library_tube_b,
        receptacle: mx_library_tube
      )
    end
    let!(:mx_aliquot_c) { create(:tagged_aliquot, library: library_tube_b, receptacle: mx_library_tube) }

    let!(:lane) { create(:lane) }
    let!(:lane_aliquot_a) do
      create(
        :aliquot,
        sample: sample_a,
        tag: sample_a_orig_tag,
        tag2: sample_a_orig_tag2,
        library: library_tube_a,
        receptacle: lane
      )
    end

    let!(:flowcell_message) do
      batch = create(:sequencing_batch, request_attributes: [{ target_asset: lane }])
      create(:flowcell_messenger, target: batch)
    end

    context 'with only tag 1' do
      let(:sample_a_new_tag2) { sample_a_orig_tag2 }
      let(:sample_b_new_tag2) { sample_b_orig_tag2 }

      let(:instructions) do
        [
          {
            sample_id: sample_a.id,
            library_id: library_tube_a.receptacle.id,
            original_tag_id: sample_a_orig_tag.id,
            substitute_tag_id: sample_a_new_tag.id
          },
          {
            sample_id: sample_b.id,
            library_id: library_tube_b.receptacle.id,
            original_tag_id: sample_b_orig_tag.id,
            substitute_tag_id: sample_b_new_tag.id
          },
          {
            sample_id: mx_aliquot_c.sample_id,
            library_id: library_tube_b.receptacle.id,
            original_tag_id: mx_aliquot_c.tag_id,
            substitute_tag_id: mx_aliquot_c.tag_id
          }
        ]
      end

      let(:comment) { <<~COMMENT }
        Tag substitution performed.
        Sample #{sample_a.id}: Tag changed from #{sample_a_orig_tag.oligo} to #{sample_a_new_tag.oligo};
        Sample #{sample_b.id}: Tag changed from #{sample_b_orig_tag.oligo} to #{sample_b_new_tag.oligo};
      COMMENT

      it_behaves_like 'tag substitution'

      context 'with user-ticket-comment info' do
        let(:additional_parameters) do
          { user: create(:user), ticket: '12345', comment: 'I wanted my tags to spell CAT TAG' }
        end
        let(:comment) { <<~COMMENT }
          Tag substitution performed.
          Referenced ticket no: 12345
          Reason: I wanted my tags to spell CAT TAG
          Sample #{sample_a.id}: Tag changed from #{sample_a_orig_tag.oligo} to #{sample_a_new_tag.oligo};
          Sample #{sample_b.id}: Tag changed from #{sample_b_orig_tag.oligo} to #{sample_b_new_tag.oligo};
        COMMENT
      end
    end

    context 'with untagged tagged2' do
      let(:sample_a_orig_tag2) { nil }
      let(:sample_b_orig_tag2) { nil }
      let(:sample_a_new_tag2) { nil }
      let(:sample_b_new_tag2) { nil }

      let(:instructions) do
        [
          {
            sample_id: sample_a.id,
            library_id: library_tube_a.receptacle.id,
            original_tag_id: sample_a_orig_tag.id,
            substitute_tag_id: sample_a_new_tag.id,
            original_tag2_id: -1,
            substitute_tag2_id: -1
          },
          {
            sample_id: sample_b.id,
            library_id: library_tube_b.receptacle.id,
            original_tag_id: sample_b_orig_tag.id,
            substitute_tag_id: sample_b_new_tag.id,
            original_tag2_id: -1,
            substitute_tag2_id: -1
          }
        ]
      end

      let(:comment) { <<~COMMENT }
        Tag substitution performed.
        Sample #{sample_a.id}: Tag changed from #{sample_a_orig_tag.oligo} to #{sample_a_new_tag.oligo};
        Sample #{sample_b.id}: Tag changed from #{sample_b_orig_tag.oligo} to #{sample_b_new_tag.oligo};
      COMMENT

      it_behaves_like 'tag substitution'

      context 'with user-ticket-comment info' do
        let(:additional_parameters) do
          { user: create(:user), ticket: '12345', comment: 'I wanted my tags to spell CAT TAG' }
        end
        let(:comment) { <<~COMMENT }
          Tag substitution performed.
          Referenced ticket no: 12345
          Reason: I wanted my tags to spell CAT TAG
          Sample #{sample_a.id}: Tag changed from #{sample_a_orig_tag.oligo} to #{sample_a_new_tag.oligo};
          Sample #{sample_b.id}: Tag changed from #{sample_b_orig_tag.oligo} to #{sample_b_new_tag.oligo};
        COMMENT
      end
    end

    context 'with tag2s defined' do
      let(:sample_a_new_tag2) { sample_b_orig_tag2 }
      let(:sample_b_new_tag2) { sample_a_orig_tag2 }

      let(:comment) { <<~COMMENT }
        Tag substitution performed.
        Sample #{sample_a.id}: Tag changed from #{sample_a_orig_tag.oligo} to #{sample_a_new_tag.oligo}; Tag2 changed from #{sample_a_orig_tag2.oligo} to #{sample_a_new_tag2.oligo};
        Sample #{sample_b.id}: Tag changed from #{sample_b_orig_tag.oligo} to #{sample_b_new_tag.oligo}; Tag2 changed from #{sample_b_orig_tag2.oligo} to #{sample_b_new_tag2.oligo};
      COMMENT

      let(:instructions) do
        [
          {
            sample_id: sample_a.id,
            library_id: library_tube_a.receptacle.id,
            original_tag_id: sample_a_orig_tag.id,
            substitute_tag_id: sample_b_orig_tag.id,
            original_tag2_id: sample_a_orig_tag2.id,
            substitute_tag2_id: sample_a_new_tag2.id
          },
          {
            sample_id: sample_b.id,
            library_id: library_tube_b.receptacle.id,
            original_tag_id: sample_b_orig_tag.id,
            substitute_tag_id: sample_a_orig_tag.id,
            original_tag2_id: sample_b_orig_tag2.id,
            substitute_tag2_id: sample_b_new_tag2.id
          }
        ]
      end

      it_behaves_like 'tag substitution'

      describe 'TagSubstitution.new(template_asset: asset)' do
        subject { described_class.new(template_asset: mx_library_tube) }

        it 'populates the basics' do
          expect(subject.substitutions.length).to eq mx_library_tube.aliquots.count
          indexed = subject.substitutions.index_by(&:sample_id)

          expect(indexed[sample_a.id]).to have_attributes(
            library_id: library_tube_a.receptacle.id,
            original_tag_id: sample_a_orig_tag.id,
            substitute_tag_id: sample_a_orig_tag.id,
            original_tag2_id: sample_a_orig_tag2.id,
            substitute_tag2_id: sample_a_orig_tag2.id
          )

          expect(indexed[sample_b.id]).to have_attributes(
            original_tag_id: sample_b_orig_tag.id,
            substitute_tag_id: sample_b_orig_tag.id,
            original_tag2_id: sample_b_orig_tag2.id,
            substitute_tag2_id: sample_b_orig_tag2.id
          )
        end
      end
    end

    context 'when details don\'t match' do
      let(:instructions) do
        [
          {
            sample_id: sample_a.id,
            library_id: library_tube_a.receptacle.id,
            original_tag_id: sample_b_orig_tag.id,
            substitute_tag_id: sample_a_orig_tag.id,
            original_tag2_id: sample_a_orig_tag2.id,
            substitute_tag2_id: sample_b_orig_tag2.id
          },
          {
            sample_id: sample_b.id,
            library_id: library_tube_b.receptacle.id,
            original_tag_id: sample_a_orig_tag.id,
            substitute_tag_id: sample_b_orig_tag.id,
            original_tag2_id: sample_b_orig_tag2.id,
            substitute_tag2_id: sample_a_orig_tag2.id
          }
        ]
      end

      it 'return false and an error of the details don\'t match' do
        expect(subject.save).to be false
        assert_includes subject.errors.full_messages, 'Substitution ["Matching aliquots could not be found"]'
      end
    end

    context 'when other attributes are updated' do
      let(:instructions) do
        [
          {
            sample_id: sample_a.id,
            library_id: library_tube_a.receptacle.id,
            original_tag_id: sample_a_orig_tag.id,
            substitute_tag_id: sample_a_orig_tag.id,
            library_type: library_type.name,
            insert_size_from: 20,
            insert_size_to: 400
          },
          {
            sample_id: sample_b.id,
            library_id: library_tube_b.receptacle.id,
            original_tag_id: sample_b_orig_tag.id,
            substitute_tag_id: sample_b_orig_tag.id,
            library_type: library_type.name,
            insert_size_from: 20,
            insert_size_to: 400
          }
        ]
      end

      let(:comment) { <<~COMMENT }
        Tag substitution performed.
        Sample #{sample_a.id}: Tag changed from #{sample_a_orig_tag.oligo} to #{sample_a_new_tag.oligo};
        Sample #{sample_b.id}: Tag changed from #{sample_b_orig_tag.oligo} to #{sample_b_new_tag.oligo};
      COMMENT

      before { assert subject.save, "TagSubstitution did not save. #{subject.errors.full_messages}" }

      it 'also update allow update of other attributes' do
        [library_aliquot_a, library_aliquot_b, mx_aliquot_a, mx_aliquot_b].each do |aliquot|
          aliquot.reload
          expect(library_type.name).to eq(aliquot.library_type)
          expect(aliquot.insert_size_from).to eq(20)
          expect(aliquot.insert_size_to).to eq(400)
        end
      end
    end
  end

  context 'with a multi-tag sample tag swap' do
    let(:sample_a_orig_tag_a) { create(:tag) }
    let(:sample_b_orig_tag_a) { create(:tag) }
    let(:sample_a_orig_tag_b) { create(:tag) }
    let(:sample_b_orig_tag_b) { create(:tag) }
    let(:other_tag) { create(:tag) }

    # Build aliquots
    let!(:library_aliquot_a_a) do
      create(:aliquot, sample: sample_a, tag: sample_a_orig_tag_a, library: library_tube_a, receptacle: library_tube_a)
    end
    let!(:library_aliquot_a_b) do
      create(:aliquot, sample: sample_a, tag: sample_a_orig_tag_b, library: library_tube_a, receptacle: library_tube_a)
    end
    let!(:library_aliquot_b_a) do
      create(:aliquot, sample: sample_b, tag: sample_b_orig_tag_a, library: library_tube_b, receptacle: library_tube_b)
    end
    let!(:library_aliquot_b_b) do
      create(:aliquot, sample: sample_b, tag: sample_b_orig_tag_b, library: library_tube_b, receptacle: library_tube_b)
    end
    let!(:mx_aliquot_a_a) do
      create(:aliquot, sample: sample_a, tag: sample_a_orig_tag_a, library: library_tube_a, receptacle: mx_library_tube)
    end
    let!(:mx_aliquot_a_b) do
      create(:aliquot, sample: sample_a, tag: sample_a_orig_tag_b, library: library_tube_a, receptacle: mx_library_tube)
    end
    let!(:mx_aliquot_b_a) do
      create(:aliquot, sample: sample_b, tag: sample_b_orig_tag_a, library: library_tube_b, receptacle: mx_library_tube)
    end
    let!(:mx_aliquot_b_b) do
      create(:aliquot, sample: sample_b, tag: sample_b_orig_tag_b, library: library_tube_b, receptacle: mx_library_tube)
    end

    let(:instructions) do
      [
        {
          sample_id: sample_a.id,
          library_id: library_tube_a.receptacle.id,
          original_tag_id: sample_a_orig_tag_a.id,
          substitute_tag_id: sample_b_orig_tag_a.id
        },
        {
          sample_id: sample_a.id,
          library_id: library_tube_a.receptacle.id,
          original_tag_id: sample_a_orig_tag_b.id,
          substitute_tag_id: other_tag.id
        },
        {
          sample_id: sample_b.id,
          library_id: library_tube_b.receptacle.id,
          original_tag_id: sample_b_orig_tag_a.id,
          substitute_tag_id: sample_a_orig_tag_a.id
        }
      ]
    end

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
