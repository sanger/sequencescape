# frozen_string_literal: true

module SampleManifestExcel
  module Upload
    module Processor
      ##
      # Processes the upload of a compound sample tube manifest, e.g. Kinnex.
      # Each row is a component sample, and all the rows of a tube show that
      # tube's barcode.
      class CompoundTube < SampleManifestExcel::Upload::Processor::Base
        BARCODE_FOR_TWO_TUBES = 'Barcode is used for more than one tube.'
        TUBE_WITH_TWO_BARCODES = 'Tube has more than one barcode.'

        private

        # The rows of a tube share its barcode. So instead of each row having
        # a different barcode, a barcode must belong to only one tube and a
        # tube must have only one barcode.
        def check_for_barcodes_unique
          row, message = row_with_inconsistent_barcode
          return if row.nil?

          errors.add(:base, "#{row.row_title} #{message}")
        end

        def row_with_inconsistent_barcode
          tubes_by_barcode = {}
          barcodes_by_tube = {}
          barcoded_rows.each do |row, barcode, tube_id|
            known_tube = tubes_by_barcode[barcode] ||= tube_id
            return row, BARCODE_FOR_TWO_TUBES unless known_tube == tube_id

            known_barcode = barcodes_by_tube[tube_id] ||= barcode
            return row, TUBE_WITH_TWO_BARCODES unless known_barcode == barcode
          end
          nil
        end

        # Each row with a barcode and a tube of the manifest, with both.
        def barcoded_rows
          return [] unless upload.respond_to?(:rows)

          upload.rows.filter_map do |row|
            next if row.columns.blank? || row.data.blank?

            barcode = row.value('sanger_tube_id')
            tube_id = tube_id_for(row.value('sanger_sample_id'))
            [row, barcode, tube_id] if barcode && tube_id
          end
        end

        def tube_id_for(sanger_sample_id)
          upload.cache.find_by(sanger_sample_id:)&.asset&.labware_id
        end
      end
    end
  end
end
