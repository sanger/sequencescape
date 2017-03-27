module SampleManifestExcel
  module Upload

    ##
    # Process the data for an upload
    # The way it is processed depends on the manifest type.
    module Processor
      require_relative 'processor/base'
      require_relative 'processor/one_d_tube'
      require_relative 'processor/multiplexed_library_tube'
    end
  end
end
