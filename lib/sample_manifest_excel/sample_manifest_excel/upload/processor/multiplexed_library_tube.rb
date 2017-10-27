module SampleManifestExcel
  module Upload
    module Processor
      ##
      # Processed slightly differently from Base
      # *Checks that the tag sequences are unique
      # *If valid transfers aliquots from library tubes to multiplexed library tubes.
      class MultiplexedLibraryTube < Base
        include Tags::Validator::Uniqueness

        def run(tag_group)
          if valid?
            update_samples_and_transfer_aliquots(tag_group)
            cancel_unprocessed_external_library_creation_requests
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

        # if partial manifest was uploaded, we do not want to give an option to upload the remaining samples
        # the reason is if aliquots were transferred downstream, it is difficult to find all downstream tubes
        # and add the remaining aliquots there
        # Also it does not make sense in real life
        def cancel_unprocessed_external_library_creation_requests
          upload.sample_manifest.pending_external_library_creation_requests.each do |request|
            request.cancel!
          end
        end
      end
    end
  end
end
