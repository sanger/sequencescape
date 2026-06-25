# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # The primer panel must exist in the primer_panels table and is identified by
    # its name. It is set as an association on aliquot.
    class PrimerPanel
      include Base

      validate :check_primer_panel_exists, if: :value?

      def update(_attributes = {})
        return unless valid? && aliquots.present?

        aliquots.each { |aliquot| aliquot.primer_panel = primer_panel }
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
