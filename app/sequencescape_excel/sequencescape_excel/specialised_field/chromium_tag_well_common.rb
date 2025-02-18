# frozen_string_literal: true
module SequencescapeExcel
  module SpecialisedField
    ##
    # ChromiumTagWellCommon
    #
    # This concern provides common functionality for Chromium tag wells.
    # It includes validation, linking, and updating methods for tag wells.
    module ChromiumTagWellCommon
      extend ActiveSupport::Concern

      TAGS_PER_WELL = 4

      included do
        include Base

        attr_accessor :sf_tag_group

        validates :well_index, presence: { message: 'is not valid' }
        validates :tags, length: { is: TAGS_PER_WELL, message: 'does not have associated tags' }, if: :well_index
        validates :aliquot_count, inclusion: { in: [1, TAGS_PER_WELL], message: 'is unexpected' }

        ##
        # Links the tag well to other fields.
        #
        # This method links the tag well to other fields, such as the tag group.
        #
        # @param other_fields [Hash] The other fields to link to.
        define_method(:link) { |other_fields| self.sf_tag_group = other_fields[self.class.tag_group_class] }

        ##
        # Updates the tag well.
        #
        # This method updates the tag well if it is valid. It assigns tags to aliquots
        # based on the number of aliquots.
        #
        # @param _attributes [Hash] The attributes to update (optional).
        define_method(:update) do |_attributes = {}|
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

      module ClassMethods
        ##
        # Returns the class of the associated tag group.
        #
        # This method should be implemented by the including class to return the class
        # that represents the associated tag group for this tag well.
        #
        # @return [Class] The class of the associated tag group.
        def tag_group_class
          raise NotImplementedError, "This #{self.class} cannot respond to:"
        end
      end
    end
  end
end
