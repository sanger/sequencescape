# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # The library type is a value which must already exist.
    # Weirdly the library type is stored as a value rather than an association.
    class PrimerPanel
      include Base

      validate :check_primer_panel_exists, if: :value?

      def update(attributes = {})
        return unless valid? && attributes[:aliquot].present?

        aliquots.each do |aliquot|
          aliquot.primer_panel = primer_panel
        end
      end

      private

      def value?
        value.present?
      end

      def primer_panel
        @primer_panel ||= ::PrimerPanel.find_by(name: value) if value?
      end

      def check_primer_panel_exists
        return if primer_panel.present?

        errors.add(:base, "could not find #{value} primer panel.")
      end
    end
  end
end
