# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # ChromiumSingleIndexTagGroup
    #
    # This class represents a single index tag group for Chromium.
    # It includes common functionality from ChromiumTagGroupCommon.
    class ChromiumSingleIndexTagGroup
      include ChromiumTagGroupCommon

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

      # Additional functionality specific to ChromiumSingleIndexTagGroup can be added here
    end
  end
end
