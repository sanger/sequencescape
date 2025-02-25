# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # ChromiumTagGroup
    #
    # This class represents a single index tag group for Chromium.
    # It includes common functionality from ChromiumTagGroupCommon.
    class ChromiumTagGroup
      include Base

      validate :check_tag_group

      ##
      # Retrieves the ID of the tag group.
      #
      # This method finds the tag group ID by searching within the
      # visible_single_index_chromium scope of the TagSet model.
      #
      # @return [Integer, nil] The ID of the tag group, or nil if not found.
      def tag_group_id
        tag_groups = ::TagSet.tag_groups_within_visible_single_index_chromium
        @tag_group_id ||= tag_groups.find_by(name: value)&.id
      end

      private

      ##
      # Validates the presence of the tag group.
      #
      # This method checks if the tag group ID is present. If not, it adds an error
      # indicating that the tag group could not be found.
      def check_tag_group
        return if tag_group_id.present?

        errors.add(:base, "could not find a chromium tag group with name #{value}.")
      end
    end
  end
end
