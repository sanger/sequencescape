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
        TAG_FIELD = SequencescapeExcel::SpecialisedField::ComponentTagSequence
        LIBRARY_TYPE_FIELD = SequencescapeExcel::SpecialisedField::LibraryType

        # After the component samples, creates a compound sample for each tube
        # with filled rows. Blank rows are not in the upload, so a blank tube
        # gets no compound sample.
        def run(tag_group)
          super
          create_compound_samples if sample_manifest_updated?
        end

        def processed?
          super && compound_samples_created?
        end

        def compound_samples_created?
          @compound_samples_created || false
        end

        private

        def create_compound_samples
          @compound_samples_created =
            upload.rows.group_by(&:asset).all? do |receptacle, rows|
              compound_sample_for(receptacle, rows)
            end
        rescue ActiveRecord::RecordInvalid => e
          @compound_samples_created = log_error_and_return_false(e.message)
        end

        # On a re-upload the tube already has its compound sample. Like other
        # manifests, only the rows saved by this upload change it: new rows
        # add component samples, and with an override, corrected tags and
        # metadata are applied. Rows skipped without an override change
        # nothing, and cleared rows do not remove component samples.
        def compound_sample_for(receptacle, rows)
          compound = receptacle.aliquots.first&.sample
          return build_compound_sample(receptacle, rows) if compound.nil?

          updated_rows = rows.select(&:sample_updated?)
          compound_sample_builder(receptacle, updated_rows).update!(compound)
        end

        def build_compound_sample(receptacle, rows)
          library_type = library_type_of(rows.first)
          compound_sample_builder(receptacle, rows, library_type).build!
        end

        def compound_sample_builder(receptacle, rows, library_type = nil)
          SampleManifest::CompoundSampleBuilder.new(
            study: upload.sample_manifest.study,
            receptacle: receptacle,
            tags_by_component: tags_by_component(rows),
            library_type: library_type
          )
        end

        def tags_by_component(rows)
          rows.to_h { |row| [row.sample, tag_of(row)] }
        end

        def tag_of(row)
          field_of(row, TAG_FIELD)&.tag
        end

        def library_type_of(row)
          field_of(row, LIBRARY_TYPE_FIELD)&.value
        end

        def field_of(row, field_class)
          row.specialised_fields.find { |field| field.is_a?(field_class) }
        end

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
