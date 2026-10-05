# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # ComponentTagSequence
    # The tag sequence of a component sample in a compound sample manifest.
    # It must match a tag in the Iso-Seq_cDNA_amp_primer tag group; at
    # present only the Kinnex compound sample manifests use this column.
    #
    # Unlike {I7}, this does not update aliquots: these component samples
    # have no aliquots. The tag is stored on the link between the compound
    # and component samples instead.
    class ComponentTagSequence
      include Base
      include ValueRequired

      TAG_GROUP_NAME = 'Iso-Seq_cDNA_amp_primer'

      validate :check_tag_exists

      # Returns the tag in the tag group whose oligo matches the value, or
      # nil if there is none.
      def tag
        return if value.blank?

        @tag ||= tag_group&.tags&.find_by(oligo: value.upcase)
      end

      private

      def tag_group
        ::TagGroup.find_by(name: TAG_GROUP_NAME)
      end

      def check_tag_exists
        return if value.blank? || tag.present?

        errors.add(
          :base,
          'Component tag sequence must match a tag in the ' \
          "#{TAG_GROUP_NAME} tag group"
        )
      end
    end
  end
end
