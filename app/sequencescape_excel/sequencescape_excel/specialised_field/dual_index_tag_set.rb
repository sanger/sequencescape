# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # DualIndexTagSet
    class DualIndexTagSet
      include Base

      validate :check_dual_index_tag_set

      def tag_set_id
        @tag_set_id ||= ::TagSet.visible_dual_index_tag_sets.find_by(name: value)&.id
      end

      private

      # Check the TagSet exists here, check the TagSet/TagWell combination in DualIndexTagWell
      def check_dual_index_tag_set
        return if tag_set_id.present?

        errors.add(:base, "could not find a visible dual index tag set with name #{value}.")
      end
    end
  end
end
