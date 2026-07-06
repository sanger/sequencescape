# frozen_string_literal: true

module SampleManifestExcel
  module Upload
    module Processor
      # TODO: had to explicitly specify the namespace for Base here otherwise it picks up Upload::Base
      class LibraryTube < SampleManifestExcel::Upload::Processor::Base
      end
    end
  end
end
