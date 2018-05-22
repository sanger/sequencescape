# frozen_string_literal: true

module SampleManifestExcel
  module SpecialisedField
    ##
    # A required field if it is a tube manifest.
    # Checked to ensure that it is the same as the sanger human barcode for sample,
    # or is a valid foreign barcode.
    # Updated if there is a valid foreign barcode.
    class SangerTubeId
      include Base
      include ValueRequired

      attr_reader :foreign_barcode_format

      validate :check_container

      def update(attributes = {})
        return unless valid? && attributes[:aliquot].present? && foreign_barcode_format.present?
        # if this tube's list of barcodes already contains a foreign barcode with the same format then update the existing one
        foreign_barcode = attributes[:aliquot].receptacle.barcodes.find { |item| item[:format] == foreign_barcode_format.to_s }
        if foreign_barcode.present?
          if foreign_barcode.barcode != value
            foreign_barcode.update(barcode: value)
            attributes[:aliquot].sample.sample_manifest.update_barcodes if attributes[:aliquot].sample.sample_manifest.present?
          end
        else
          attributes[:aliquot].receptacle.barcodes << Barcode.new(format: foreign_barcode_format, barcode: value)
          attributes[:aliquot].sample.sample_manifest.update_barcodes if attributes[:aliquot].sample.sample_manifest.present?
        end
      end

      private

      def check_container
        return if value == sample.assets.first.human_barcode
        check_for_foreign_barcode
      end

      def check_for_foreign_barcode
        @foreign_barcode_format = Barcode.matches_any_foreign_barcode_format?(value)
        if foreign_barcode_format.present?
          check_foreign_barcode_unique
        else
          errors.add(:sample, 'If you modify the sample container barcode it must be to a valid foreign barcode format')
        end
      end

      def check_foreign_barcode_unique
        return if Barcode.unique_for_format?(foreign_barcode_format, value).blank?
        errors.add(:sample, 'The sample container foreign barcode is already in use.')
      end
    end
  end
end
