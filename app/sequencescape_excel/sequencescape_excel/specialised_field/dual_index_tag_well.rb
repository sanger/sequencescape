# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # DualIndexTagWell
    class DualIndexTagWell
      # 2 tags in the well, 1 tag from tag_group and 1 tag from tag2_group
      TAGS_PER_WELL = 2

      include Base
      # TODO: Is the value required?
      # include ValueRequired

      attr_accessor :sf_dual_index_tag_set

      validates :well_index, presence: { message: 'is not valid' }
      validates :tags, length: { is: TAGS_PER_WELL, message: 'does not have associated tags' }, if: :well_index

      def update(_attributes = {})
        # TODO
        # assuming there is only 1 aliquot in the well (asset)
        # so can do a check
        # add the (hopefully) two tags to the well.aliquots
      end

      def link(other_fields)
        self.sf_dual_index_tag_set = other_fields[SequencescapeExcel::SpecialisedField::DualIndexTagSet]
      end

      def dual_index_tag_set
        @dual_index_tag_set = TagSet.find(sf_dual_index_tag_set&.tag_set_id) if sf_dual_index_tag_set&.tag_set_id
      end

      def tag_group_id
        @tag_group_id ||= ::TagGroup.find_by(id: dual_index_tag_set&.tag_group_id, visible: true)&.id
      end

      def tag2_group_id
        @tag2_group_id ||= ::TagGroup.find_by(id: dual_index_tag_set&.tag2_group_id, visible: true)&.id
      end

      private

      # A1 --> 1
      # B1 --> 2
      # ...
      # H12 --> 96
      def well_index
        @well_index = Map::Coordinate.description_to_vertical_plate_position(value, 96)
      end

      def tags
        Tag.where(tag_group_id: [tag_group_id, tag2_group_id], map_id: well_index)
      end
    end
  end
end
