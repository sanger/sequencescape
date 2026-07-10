# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # DualIndexTagSet
    class DualIndexTagSet
      include Base
      include ValueRequired

      validate :dual_index_tag_set

      def tag_set_id
        @tag_set_id ||= ::TagSet.dual_index.visible.find_by(name: value)&.id
      end

      private

      # Check the Dual Index Tag Set with a visible tag_group and tag2_group exists here
      # Check the TagSet/TagWell combination in DualIndexTagWell
      def dual_index_tag_set
        return if tag_set_id.present?

        errors.add(:base, "could not find a visible dual index Tag Set with name '#{value}'.")
      end
    end
  end
end
