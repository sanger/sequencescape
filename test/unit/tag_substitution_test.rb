require 'test_helper'

class TagSubstitutionTest < ActiveSupport::TestCase
  # We have a large number of scenarios here, because unfortunately
  # things can get quite complicated.

  context 'TagSubstitution' do
    context 'with a simple tag swap' do
      # Works for: Library manifests, old tube pipelines
      # We have two samples, each with unique tags, which only exist
      # in aliquots identified by the library id. We don't need to consider:
      # - Tagged aliquots without a library id (eg. External pipeline apps)
      # - Multiple tags for the same sample/library (Chromium pipelines)
      # - Introducing invalid state through persisting tag clashes. (Theoretically any pipline, but esp. Generic Lims QC pools)
      # Note: The tag swap scenario used here is important, as a naive approach results in a temporary tag clash. If you make
      # changes to this suite, please ensure this scenario is still tested.
      setup do
        @sample_a = create :sample
        @sample_b = create :sample
        @sample_a_orig_tag  = create :tag
        @sample_a_orig_tag2 = create :tag
        @sample_b_orig_tag  = create :tag
        @sample_b_orig_tag2 = create :tag

        @library_tube_a = create :library_tube
        @library_aliquot_a = create :aliquot, sample: @sample_a, tag: @sample_a_orig_tag, tag2: @sample_a_orig_tag2, library: @library_tube_a, receptacle: @library_tube_a

        @library_tube_b = create :library_tube
        @library_aliquot_b = create :aliquot, sample: @sample_b, tag: @sample_b_orig_tag, tag2: @sample_b_orig_tag2, library: @library_tube_b, receptacle: @library_tube_b

        @mx_library_tube = create :multiplexed_library_tube
        @mx_aliquot_a = create :aliquot, sample: @sample_a, tag: @sample_a_orig_tag, tag2: @sample_a_orig_tag2, library: @library_tube_a, receptacle: @mx_library_tube
        @mx_aliquot_b = create :aliquot, sample: @sample_b, tag: @sample_b_orig_tag, tag2: @sample_b_orig_tag2, library: @library_tube_b, receptacle: @mx_library_tube
      end

      should 'perform the correct tag substitutions' do
        instructions = [
          { sample_id: @sample_a.id, library_id: @library_tube_a.id, original_tag_id: @sample_a_orig_tag.id, substitute_tag_id: @sample_b_orig_tag.id },
          { sample_id: @sample_b.id, library_id: @library_tube_b.id, original_tag_id: @sample_b_orig_tag.id, substitute_tag_id: @sample_a_orig_tag.id }
        ]
        ts = TagSubstitution.new(instructions)
        assert ts.save, "TagSubstitution did not save. #{ts.errors.full_messages}"
        assert_equal @library_aliquot_a.reload.tag, @sample_b_orig_tag
        assert_equal @library_aliquot_b.reload.tag, @sample_a_orig_tag
        assert_equal @mx_aliquot_a.reload.tag, @sample_b_orig_tag
        assert_equal @mx_aliquot_b.reload.tag, @sample_a_orig_tag
      end

      should 'perform the correct tag2 substitutions' do
        instructions = [
          { sample_id: @sample_a.id, library_id: @library_tube_a.id, original_tag_id: @sample_a_orig_tag.id, substitute_tag_id: @sample_b_orig_tag.id, original_tag2_id: @sample_a_orig_tag2.id, substitute_tag2_id: @sample_b_orig_tag2.id },
          { sample_id: @sample_b.id, library_id: @library_tube_b.id, original_tag_id: @sample_b_orig_tag.id, substitute_tag_id: @sample_a_orig_tag.id, original_tag2_id: @sample_b_orig_tag2.id, substitute_tag2_id: @sample_a_orig_tag2.id }
        ]
        ts = TagSubstitution.new(instructions)
        assert ts.save, "TagSubstitution did not save. #{ts.errors.full_messages}"
        assert_equal @library_aliquot_a.reload.tag, @sample_b_orig_tag
        assert_equal @library_aliquot_b.reload.tag, @sample_a_orig_tag
        assert_equal @mx_aliquot_a.reload.tag, @sample_b_orig_tag
        assert_equal @mx_aliquot_b.reload.tag, @sample_a_orig_tag
        assert_equal @library_aliquot_a.reload.tag2, @sample_b_orig_tag2
        assert_equal @library_aliquot_b.reload.tag2, @sample_a_orig_tag2
        assert_equal @mx_aliquot_a.reload.tag2, @sample_b_orig_tag2
        assert_equal @mx_aliquot_b.reload.tag2, @sample_a_orig_tag2
      end

      should 'return false and an error of the details don\'t match' do
        instructions = [
          { sample_id: @sample_a.id, library_id: @library_tube_a.id, original_tag_id: @sample_b_orig_tag.id, substitute_tag_id: @sample_a_orig_tag.id, original_tag2_id: @sample_a_orig_tag2.id, substitute_tag2_id: @sample_b_orig_tag2.id },
          { sample_id: @sample_b.id, library_id: @library_tube_b.id, original_tag_id: @sample_a_orig_tag.id, substitute_tag_id: @sample_b_orig_tag.id, original_tag2_id: @sample_b_orig_tag2.id, substitute_tag2_id: @sample_a_orig_tag2.id }
        ]
        ts = TagSubstitution.new(instructions)
        refute ts.save, 'Substitution saved when it should have errord'
        assert_includes ts.errors.full_messages, 'Substitution Matching aliquots could not be found'
      end

      should 'also update allow update of other attributes' do
        @library_type = create :library_type
        instructions = [
          { sample_id: @sample_a.id, library_id: @library_tube_a.id, original_tag_id: @sample_a_orig_tag.id, substitute_tag_id: @sample_a_orig_tag.id, library_type: @library_type.name, insert_size_from: 20, insert_size_to: 400 },
          { sample_id: @sample_b.id, library_id: @library_tube_b.id, original_tag_id: @sample_b_orig_tag.id, substitute_tag_id: @sample_b_orig_tag.id, library_type: @library_type.name, insert_size_from: 20, insert_size_to: 400 }
        ]
        ts = TagSubstitution.new(instructions)
        assert ts.save, "TagSubstitution did not save. #{ts.errors.full_messages}"

        [@library_aliquot_a, @library_aliquot_b, @mx_aliquot_a, @mx_aliquot_b].each do |aliquot|
          aliquot.reload
          assert_equal aliquot.library_type, @library_type.name
          assert_equal 20, aliquot.insert_size_from
          assert_equal 400, aliquot.insert_size_to
        end
      end
    end

    context 'with a multi-tag sample tag swap' do
      setup do
        @sample_a = create :sample
        @sample_b = create :sample
        @sample_a_orig_tag_a  = create :tag
        @sample_b_orig_tag_a  = create :tag
        @sample_a_orig_tag_b  = create :tag
        @sample_b_orig_tag_b  = create :tag
        @other_tag            = create :tag

        @library_tube_a = create :library_tube
        @library_aliquot_a_a = create :aliquot, sample: @sample_a, tag: @sample_a_orig_tag_a, library: @library_tube_a, receptacle: @library_tube_a
        @library_aliquot_a_b = create :aliquot, sample: @sample_a, tag: @sample_a_orig_tag_b, library: @library_tube_a, receptacle: @library_tube_a

        @library_tube_b = create :library_tube
        @library_aliquot_b_a = create :aliquot, sample: @sample_b, tag: @sample_b_orig_tag_a, library: @library_tube_b, receptacle: @library_tube_b
        @library_aliquot_b_b = create :aliquot, sample: @sample_b, tag: @sample_b_orig_tag_b, library: @library_tube_b, receptacle: @library_tube_b

        @mx_library_tube = create :multiplexed_library_tube
        @mx_aliquot_a_a = create :aliquot, sample: @sample_a, tag: @sample_a_orig_tag_a, library: @library_tube_a, receptacle: @mx_library_tube
        @mx_aliquot_a_b = create :aliquot, sample: @sample_a, tag: @sample_a_orig_tag_b, library: @library_tube_a, receptacle: @mx_library_tube
        @mx_aliquot_b_a = create :aliquot, sample: @sample_b, tag: @sample_b_orig_tag_a, library: @library_tube_b, receptacle: @mx_library_tube
        @mx_aliquot_b_b = create :aliquot, sample: @sample_b, tag: @sample_b_orig_tag_b, library: @library_tube_b, receptacle: @mx_library_tube
      end

      should 'perform the correct substitutions' do
        instructions = [
          { sample_id: @sample_a.id, library_id: @library_tube_a.id, original_tag_id: @sample_a_orig_tag_a.id, substitute_tag_id: @sample_b_orig_tag_a.id },
          { sample_id: @sample_a.id, library_id: @library_tube_a.id, original_tag_id: @sample_a_orig_tag_b.id, substitute_tag_id: @other_tag.id },
          { sample_id: @sample_b.id, library_id: @library_tube_b.id, original_tag_id: @sample_b_orig_tag_a.id, substitute_tag_id: @sample_a_orig_tag_a.id }
        ]
        ts = TagSubstitution.new(instructions)
        assert ts.save, "TagSubstitution did not save. #{ts.errors.full_messages}"
        assert_equal @library_aliquot_a_a.reload.tag, @sample_b_orig_tag_a
        assert_equal @library_aliquot_b_a.reload.tag, @sample_a_orig_tag_a
        assert_equal @mx_aliquot_a_a.reload.tag, @sample_b_orig_tag_a
        assert_equal @mx_aliquot_b_a.reload.tag, @sample_a_orig_tag_a

        assert_equal @library_aliquot_a_b.reload.tag, @other_tag
        assert_equal @library_aliquot_b_b.reload.tag, @sample_b_orig_tag_b
        assert_equal @mx_aliquot_a_b.reload.tag, @other_tag
        assert_equal @mx_aliquot_b_b.reload.tag, @sample_b_orig_tag_b
      end
    end
  end
end
