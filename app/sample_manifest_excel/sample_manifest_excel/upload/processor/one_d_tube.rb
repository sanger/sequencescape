# frozen_string_literal: true

require_dependency 'sample_manifest_excel/upload/processor/base'
module SampleManifestExcel
  module Upload
    module Processor
      # TODO: had to explicitly specify the namespace for Base here otherwise it picks up Upload::Base
      class OneDTube < SampleManifestExcel::Upload::Processor::Base
      end
    end
  end
end
