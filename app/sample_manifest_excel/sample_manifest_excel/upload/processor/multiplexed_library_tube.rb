# frozen_string_literal: true

require_dependency 'sample_manifest_excel/upload/processor/base'

module SampleManifestExcel
  module Upload
    module Processor
      ##
      # Processed slightly differently from Base
      # *Checks that the tags are unique
      # *If valid transfers aliquots from library tubes to multiplexed library tubes.
      # *If manifest was reuploaded, updates downstream aliquots (instead of transfer)
      # TODO: had to explicitly specify the namespace for Base here otherwise it picks up Upload::Base
      class MultiplexedLibraryTube < SampleManifestExcel::Upload::Processor::Base
        include Tags::Validator::Uniqueness

        attr_writer :substitutions

        def run(tag_group)
          return false unless valid?
          update_samples_and_aliquots(tag_group)
          cancel_unprocessed_external_library_creation_requests
          update_sample_manifest
        end

        def update_samples_and_aliquots(tag_group)
          upload.rows.each do |row|
            row.update_sample(tag_group, upload.override)
            row.transfer_aliquot # Requests are smart enough to only transfer once
            substitutions << row.aliquot.substitution_hash if upload.reuploaded?
          end
          update_downstream_aliquots if substitutions.present?
        end

        # if manifest is reuploaded, only aliquots, that are in 'fake' library tubes will be updated
        # actual aliquots in multiplexed library tube and other aliquots downstream are updated by this method
        # library updates all aliquots in one go, doing it row by row is inefficient and may trigger tag clash
        def update_downstream_aliquots
          @downstream_aliquots_updated = if no_substitutions?
                                           false
                                         else
                                           TagSubstitution.new(substitutions: substitutions.compact, comment: 'Manifest updated').save
                                         end
        end

        # if partial manifest was uploaded, we do not want to give an option to upload the remaining samples
        # the reason is if aliquots were transferred downstream, it is difficult to find all downstream tubes
        # and add the remaining aliquots there
        # Also it does not make sense in real life
        def cancel_unprocessed_external_library_creation_requests
          upload.sample_manifest.pending_external_library_creation_requests.each(&:cancel!)
        end

        def substitutions
          @substitutions ||= []
        end

        def aliquots_transferred?
          upload.rows.all?(&:aliquot_transferred?)
        end

        def downstream_aliquots_updated?
          @downstream_aliquots_updated
        end

        def processed?
          @processed ||= samples_updated? && aliquots_updated? && sample_manifest_updated?
        end

        def no_substitutions?
          substitutions.compact.all?(&:blank?)
        end

        def aliquots_updated?
          if upload.reuploaded?
            downstream_aliquots_updated? ||
              no_substitutions? ||
              log_error_and_return_false('Could not update tags in other assets.')
          else
            aliquots_transferred? || log_error_and_return_false('Could not transfer aliquots.')
          end
        end
      end
    end
  end
end
