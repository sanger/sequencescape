# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # ChromiumTagWell
    class ChromiumTagWell
      TAGS_PER_WELL = 4

      include Base

      attr_accessor :sf_tag_group

      validates :well_index, presence: { message: 'is not valid' }
      validates :tags, length: { is: TAGS_PER_WELL, message: 'does not have associated tags' }, if: :well_index
      validates :aliquot_count, inclusion: { in: [1, TAGS_PER_WELL], message: 'is unexpected' }

      def update(_attributes = {})
        return unless valid?

        if asset.aliquots.one?
          tags.each { |tag| tag.multitag!(asset) }
        elsif aliquot_count == TAGS_PER_WELL
          tags.zip(aliquots).each { |tag, aliquot| aliquot.assign_attributes(tag: tag) }
        else
          # We should never end up here, as our validation should handle this
          # However if that fails, something has gone wrong, and we shouldn't proceed
          # Fail noisily
          raise StandardError, 'Tag aliquot mismatch'
        end
      end

      def link(other_fields)
        self.sf_tag_group = other_fields[SequencescapeExcel::SpecialisedField::ChromiumTagGroup]
      end

      private

      def aliquot_count
        asset.aliquots.length
      end

      def well_index
        @well_index = Map::Coordinate.description_to_vertical_plate_position(value, 96)
      end

      def map_ids
        Array.new(TAGS_PER_WELL) { |i| ((well_index - 1) * TAGS_PER_WELL) + i + 1 }
      end

      def tags
        sf_tag_group.tag_group&.tags&.select { |tag| map_ids.include?(tag.map_id) }
      end
    end
  end
end
