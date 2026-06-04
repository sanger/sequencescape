# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # ChromiumTagGroup
    # This class represents a single index tag group for Chromium.
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
        tag_set = ::TagSet.visible_single_index_chromium.find_by(name: value)
        @tag_group_id ||= tag_set&.tag_group_id
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
