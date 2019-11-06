# frozen_string_literal: true

require_dependency 'sample_manifest_excel/upload/processor/base'

module SampleManifestExcel
  module Upload
    module Processor
      # TODO: had to explicitly specify the namespace for Base here otherwise it picks up Upload::Base
      class TubeRack < SampleManifestExcel::Upload::Processor::Base
        def run(tag_group)
          return unless valid?

          update_samples_and_aliquots(tag_group)
          # TODO: if not uploaded before,
          # create tube rack if doesn't already exist
          # update existing tube with barcode (from manifest)
            # find existing tube through sanger sample id -> sample manifest asset -> receptacle -> labware (not through aliquot, in case it's the wrong aliquot)
          # insert racked tube, with coordinate (from scan)
          update_sample_manifest
        end
      end
    end
  end
end
