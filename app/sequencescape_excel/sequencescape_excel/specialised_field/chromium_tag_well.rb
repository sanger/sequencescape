# frozen_string_literal: true
module SequencescapeExcel
  module SpecialisedField
    ##
    # ChromiumTagWell
    #
    # This class represents a single index tag well for Chromium.
    class ChromiumTagWell
      TAGS_PER_WELL = 4
      include Base

      attr_accessor :sf_tag_group

      validates :well_index, presence: { message: 'is not valid' }
      validates :tags, length: { is: TAGS_PER_WELL, message: 'does not have associated tags' }, if: :well_index
      validates :aliquot_count, inclusion: { in: [1, TAGS_PER_WELL], message: 'is unexpected' }

      ##
      # Updates the tag well.
      #
      # This method updates the tag well if it is valid. It assigns tags to aliquots
      # based on the number of aliquots.
      #
      # @param _attributes [Hash] The attributes to update (optional).

      def update(_attributes = {})
        return unless valid?

        if asset.aliquots.one?
          tags.each { |tag| tag.multitag!(asset) }
        elsif aliquot_count == TAGS_PER_WELL
          tags.zip(aliquots).each { |tag, aliquot| aliquot.assign_attributes(tag:) }
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

      ##
      # Returns the number of aliquots.
      #
      # This method returns the number of aliquots associated with the asset.
      #
      # @return [Integer] The number of aliquots.
      def aliquot_count
        asset.aliquots.length
      end

      ##
      # Returns the well index.
      #
      # Translates values on the left (well positions) to 'well index' integer on the right (column order).
      # A1 --> 1
      # B1 --> 2
      # ...
      # H12 --> 96
      #
      # @return [Integer] The well index.
      def well_index
        @well_index = Map::Coordinate.description_to_vertical_plate_position(value, 96)
      end

      ##
      # Returns the map IDs.
      #
      # This method translates well index (on the left) to the arrays on the right.
      # These 'map_id' integers refer simply to the position in the list of tags in the tag group
      # (note: it's not related to the `maps` table).
      # Viewed together with the `well_index` method, this will translate, for example,'A1' entered
      # in the tag well column of the manifest, to [1, 2, 3, 4], meaning the first 4 tags in the tag group.

      # 1 --> [1, 2, 3, 4]
      # 2 --> [5, 6, 7, 8]
      # ...
      # 96 --> [381, 382, 383, 384]
      # @return [Array<Integer>] The array of map IDs.
      def map_ids
        Array.new(TAGS_PER_WELL) { |i| ((well_index - 1) * TAGS_PER_WELL) + i + 1 }
      end

      ##
      # Returns the tags.
      #
      # This method retrieves the tags associated with the tag group and map IDs.
      #
      # @return [ActiveRecord::Relation, nil] The tags, or nil if the tag group ID is not present.

      def tags
        Tag.where(tag_group_id: sf_tag_group.tag_group_id, map_id: map_ids) if sf_tag_group&.tag_group_id
      end
    end
  end
end
