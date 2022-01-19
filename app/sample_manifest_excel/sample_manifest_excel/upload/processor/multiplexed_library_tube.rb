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
            substitutions.concat(row.aliquots.filter_map(&:substitution_hash)) if row.reuploaded?
          end
          update_downstream_aliquots unless no_substitutions?
        end

        # if partial manifest was uploaded, we do not want to give an option to upload the remaining samples
        # the reason is if aliquots were transferred downstream, it is difficult to find all downstream tubes
        # and add the remaining aliquots there
        # Also it does not make sense in real life
        def cancel_unprocessed_external_library_creation_requests
          upload.sample_manifest.pending_external_library_creation_requests.each(&:cancel!)
        end

        def processed?
          samples_updated? && aliquots_updated? && sample_manifest_updated? && aliquots_transferred?
        end

        def aliquots_transferred?
          upload.rows.all?(&:aliquot_transferred?) || log_error_and_return_false('Could not transfer aliquots.')
        end

        def disable_match_expectation
          false
        end
      end
    end
  end
end
