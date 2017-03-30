module SampleManifestExcel
  module Upload
    module Processor
      ##
      # Processed slightly differently from Base
      # *Checks that the tag sequences are unique
      # *If valid transfers aliquots from library tubes to multiplexed library tubes.
      class MultiplexedLibraryTube < Base
        include Tags::Validator

          def run(tag_group)
            if valid?
              update_samples_and_transfer_aliquots(tag_group)
              update_sample_manifest
            end
          end

          def update_samples_and_transfer_aliquots(tag_group)
            upload.rows.each do |row|
              row.update_sample(tag_group)
              row.transfer_aliquot
            end
          end

          def aliquots_transferred?
            upload.rows.all? { |row| row.aliquot_transferred? }
          end

          def processed?
            @processed ||= samples_updated? && sample_manifest_updated? && aliquots_transferred?
          end

        # private

        #   def check_tags
        #     tag_oligo_column = upload.columns.find_by(:name, :tag_oligo)
        #     tag2_oligo_column = upload.columns.find_by(:name, :tag2_oligo)
        #     if tag_oligo_column.present? & tag2_oligo_column.present?
        #       combinations = upload.data.column(tag_oligo_column.number).zip(upload.data.column(tag2_oligo_column.number))
        #       errors.add(:tags_combinations, 'are not unique') unless combinations.length == combinations.uniq.length
        #     end
        #   end
      end
    end
  end
end
