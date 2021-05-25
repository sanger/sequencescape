# frozen_string_literal: true

module SequencescapeExcel
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

      # rubocop:todo Metrics/PerceivedComplexity
      # rubocop:todo Metrics/MethodLength
      # rubocop:todo Metrics/AbcSize
      def update(attributes = {}) # rubocop:todo Metrics/CyclomaticComplexity
        return unless valid? && attributes[:aliquot].present? && foreign_barcode_format.present?

        # if this tube's list of barcodes already contains a foreign barcode with the same format then update the existing one
        foreign_barcode =
          attributes[:aliquot].receptacle.barcodes.find { |item| item[:format] == foreign_barcode_format.to_s }
        if foreign_barcode.present?
          if foreign_barcode.barcode != value
            foreign_barcode.update(barcode: value)
            if attributes[:aliquot].sample.sample_manifest.present?
              attributes[:aliquot].sample.sample_manifest.update_barcodes
            end
          end
        else
          attributes[:aliquot].receptacle.labware.barcodes <<
            Barcode.new(format: foreign_barcode_format, barcode: value)
          if attributes[:aliquot].sample.sample_manifest.present?
            attributes[:aliquot].sample.sample_manifest.update_barcodes
          end
        end
      end

      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/PerceivedComplexity

      private

      def check_container
        return if value == sample_manifest_asset.human_barcode

        check_for_foreign_barcode
      end

      def check_for_foreign_barcode
        @foreign_barcode_format = Barcode.matching_barcode_format(value)
        if foreign_barcode_format.present?
          check_foreign_barcode_unique
        else
          errors.add(:sample, 'barcode has been modified, but it is not a valid foreign barcode format')
        end
      end

      def check_foreign_barcode_unique
        return unless Barcode.exists_for_format?(foreign_barcode_format, value)

        errors.add(:sanger_tube_id, 'foreign barcode is already in use.')
      end
    end
  end
end
