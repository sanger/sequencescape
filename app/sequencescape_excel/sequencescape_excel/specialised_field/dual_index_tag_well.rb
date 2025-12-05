# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # DualIndexTagWell
    class DualIndexTagWell
      include Base
      include ValueRequired

      # ValueToUpcase converts the `value` to uppercase
      # For exqmple the `value` used in the well_index method would be 'A1' instead of 'a1'
      # This is important because the description_to_vertical_plate_position method
      # returns a different value for 'A1' vs 'a1', where the upcase version is correct
      include ValueToUpcase

      attr_accessor :sf_dual_index_tag_set

      validates :well_index, presence: { message: 'is not valid' }
      validates :tag, presence: { message: 'does not have associated i7 tag' }, if: :well_index
      validates :tag2, presence: { message: 'does not have associated i5 tag' }, if: :well_index

      PLATE_SIZE = 96

      def update(_attributes = {})
        return unless valid?

        stock_aliquot = fetch_single_aliquot(asset)
        new_i7_tag = tag
        new_i5_tag = tag2
        return unless tags_need_update?(stock_aliquot, new_i7_tag, new_i5_tag)

        # Update all downstream aliquots as well as current aliquot
        matching_aliquots = identify_all_matching_aliquots(stock_aliquot)
        update_all_relevant_aliquots(matching_aliquots, new_i7_tag, new_i5_tag)
      end

      def link(other_fields)
        self.sf_dual_index_tag_set = other_fields[SequencescapeExcel::SpecialisedField::DualIndexTagSet]
      end

      # From the validation in DualIndexTagSet, we know this tag set is a valid dual index tag set
      # with a visible tag group and visible tag2 group
      def dual_index_tag_set
        @dual_index_tag_set = TagSet.find(sf_dual_index_tag_set.tag_set_id) if sf_dual_index_tag_set&.tag_set_id
      end

      def tag_group_id
        @tag_group_id ||= ::TagGroup.find_by(id: dual_index_tag_set.tag_group_id, visible: true).id
      end

      def tag2_group_id
        @tag2_group_id ||= ::TagGroup.find_by(id: dual_index_tag_set.tag2_group_id, visible: true).id
      end

      private

      # This assumes that the tags within a tag group for dual index tags are listed in 'column' order,
      # i.e. the first tag is the one in the first column, the second tag is the one in the second column, etc.
      # therefore description_to_vertical_plate_position is used to get the correct map_id
      # A1 --> 1
      # B1 --> 2
      # ...
      # H12 --> 96
      def well_index
        @well_index = Map::Coordinate.description_to_vertical_plate_position(value, PLATE_SIZE)
      end

      # i7 tag
      def tag
        Tag.find_by(tag_group_id: tag_group_id, map_id: well_index)
      end

      # i5 tag
      def tag2
        Tag.find_by(tag_group_id: tag2_group_id, map_id: well_index)
      end

      def fetch_single_aliquot(asset)
        raise StandardError, 'Expecting asset to have a single aliquot' unless asset.aliquots.one?

        asset.aliquots.first
      end

      # Determine if the tags need to be updated
      def tags_need_update?(stock_aliquot, new_i7_tag, new_i5_tag)
        (stock_aliquot.tag != new_i7_tag) || (stock_aliquot.tag2 != new_i5_tag)
      end

      # Find all aliquots that need updating
      # Aliquots must have a matching sample_id, library_id, tag_id and tag2_id to the given stock_aliquot.
      def identify_all_matching_aliquots(stock_aliquot)
        attributes = {
          sample_id: stock_aliquot.sample_id,
          library_id: stock_aliquot.library_id,
          tag_id: stock_aliquot.tag_id,
          tag2_id: stock_aliquot.tag2_id
        }

        Aliquot.where(attributes).ids
      end

      # Update the tags in all the matching aliquots
      def update_all_relevant_aliquots(matching_aliquots, new_i7_tag, new_i5_tag)
        Aliquot.where(id: matching_aliquots).find_each do |aq|
          aq.update(tag: new_i7_tag, tag2: new_i5_tag)
          aq.save!
        end
      end
    end
  end
end
