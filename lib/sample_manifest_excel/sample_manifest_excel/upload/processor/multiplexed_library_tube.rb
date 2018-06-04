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

        attr_writer :substitutions

        def run(tag_group)
          if valid?
            update_samples_and_aliquots(tag_group)
            cancel_unprocessed_external_library_creation_requests
            update_sample_manifest
          end
        end

        def update_samples_and_aliquots(tag_group)
          upload.rows.each do |row|
            row.update_sample(tag_group)
            row.transfer_aliquot unless upload.reuploaded?
            substitutions << row.aliquot.substitution_hash if upload.reuploaded?
          end
          update_downstream_aliquots if upload.reuploaded? && substitutions.present?
        end

        # if manifest is reuploaded, only aliquots, that are in 'fake' library tubes will be updated
        # actual aliquots in multiplexed library tube and other aliquots downstream are updated by this method
        # library updates all aliquots in one go, doing it row by row is inefficient and may trigger tag clash
        def update_downstream_aliquots
          @downstream_aliquots_updated = if substitutions.compact.blank?
                                           false
                                         else
                                           TagSubstitution.new(substitutions: substitutions.compact).save
                                         end
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

        def substitutions
          @substitutions ||= []
        end

        def aliquots_transferred?
          upload.rows.all? { |row| row.aliquot_transferred? }
        end

        def downstream_aliquots_updated?
          @downstream_aliquots_updated
        end

        def processed?
          @processed ||= samples_updated? && aliquots_updated? && sample_manifest_updated?
        end

        def aliquots_updated?
          if upload.reuploaded?
            downstream_aliquots_updated? || substitutions.compact.blank?
          else
            aliquots_transferred?
          end
        end
      end
    end
  end
end
