# frozen_string_literal: true
module SequencescapeExcel
  module SpecialisedField
    ##
    # ChromiumTagGroupCommon
    #
    # This concern provides common functionality for Chromium tag groups.
    # It includes validation and methods for retrieving the tag group ID.
    module ChromiumTagGroupCommon
      extend ActiveSupport::Concern

      included do
        include Base
        validate :check_tag_group
      end

      ##
      # Retrieves the ID of the tag group.
      #
      # This method finds the tag group ID by searching within the
      # chromium scope of the TagGroup model.
      #
      # @return [Integer, nil] The ID of the tag group, or nil if not found.
      def tag_group_id
        @tag_group_id ||= ::TagGroup.chromium.find_by(name: value)&.id
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
