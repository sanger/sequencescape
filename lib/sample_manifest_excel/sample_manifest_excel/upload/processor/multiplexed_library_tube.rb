module SampleManifestExcel
  module Upload
    module Processor
      ##
      # Processed slightly differently from Base
      # *Checks that the tag sequences are unique
      # *If valid transfers aliquots from library tubes to multiplexed library tubes.
      # *If manifest was reuploaded, updates downstream aliquots (instead of transfer)
      class MultiplexedLibraryTube < Base
        include Tags::Validator::Uniqueness

        def run(tag_group)
          if valid?
            update_samples_and_transfer_aliquots(tag_group)
            update_sample_manifest
          end
        end

        def update_samples_and_transfer_aliquots(tag_group)
          upload.rows.each do |row|
            row.update_sample(tag_group)
            # if manifest is reuploaded, and new rows are filled in, should we transfer these aliquots?
            # what if other tubes were created downstream?
            row.transfer_aliquot unless upload.reuploaded?
            row.update_downstream_aliquots if upload.reuploaded?
          end
        end

        def aliquots_transferred?
          upload.rows.all? { |row| row.aliquot_transferred? }
        end

        def downstream_aliquots_updated?
          upload.rows.select { |row| row.downstream_aliquots_to_be_updated? }.all? { |row| row.downstream_aliquots_updated? }
        end

        def processed?
          @processed ||= samples_updated? && sample_manifest_updated? && aliquots_transferred_or_updated?
        end

        def aliquots_transferred_or_updated?
          if upload.reuploaded?
            downstream_aliquots_updated?
          else
            aliquots_transferred?
          end
        end
      end
    end
  end
end
