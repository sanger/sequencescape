# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # ChromiumTagGroup
    class ChromiumTagGroup
      include Base

      validate :check_tag_group

      def tag_group_id
        @tag_group_id ||= tag_group&.id
      end

      def tag_group
        cache.fetch(:chromium_tag_group, value) { ::TagGroup.chromium.find_by(name: value) }
      end

      private

      # check the group exists here, check the group/index combination in tag_index
      def check_tag_group
        return if tag_group_id.present?

        errors.add(:base, "could not find a chromium tag group with name #{value}.")
      end
    end
  end
end
