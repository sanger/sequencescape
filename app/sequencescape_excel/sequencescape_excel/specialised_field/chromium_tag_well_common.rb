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
        define_method(:link) do |other_fields|
          self.sf_tag_group = other_fields[self.class.tag_group_class]
        end

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
      # This method calculates and returns the well index based on the value.
      #
      # @return [Integer] The well index.
      def well_index
        @well_index = Map::Coordinate.description_to_vertical_plate_position(value, 96)
      end

      ##
      # Returns the map IDs.
      #
      # This method calculates and returns an array of map IDs based on the well index.
      #
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
