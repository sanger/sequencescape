# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # Tag2Group
    class Tag2Group
      include Base

      validate :check_tag2_group

      def tag2_group_id
        tag2_group&.id
      end

      def tag2_group
        @tag2_group ||= cache.fetch(:tag_group, value) { ::TagGroup.find_by(name: value) }
      end

      private

      # check the group exists here, check the group/index combination in tag2_index
      def check_tag2_group
        return if tag2_group_id.present? || value.blank?

        errors.add(:base, "could not find a tag2 group with name #{value}.")
      end
    end
  end
end
