# frozen_string_literal: true

module SampleManifestExcel
  module SpecialisedField
    ##
    # A required field if it is a tube manifest.
    # No update required.
    # Checked to ensure that it is the same as the sanger human barcode for sample.
    # Not updated
    class SangerTubeId
      include Base
      include ValueRequired

      validate :check_container

      private

      def check_container
        return if value == sample.assets.first.human_barcode
        check_for_foreign_barcode
      end

      def check_for_foreign_barcode
        return if Barcode.matches_any_foreign_barcode_format?(value).present?
        errors.add(:sample, 'If you modify the sample container barcode it must be to a valid foreign barcode format')
      end
    end
  end
end
