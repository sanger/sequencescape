# frozen_string_literal: true

module SampleManifestExcel
  module Upload
    module Processor
      # TODO: had to explicitly specify the namespace for Base here otherwise it picks up Upload::Base
      # Processor to handle 1dtube uploads
      class OneDTube < SampleManifestExcel::Upload::Processor::Base
      end
    end
  end
end
