module SampleManifestExcel

  ##
  # Upload a previously created manifest.
  module Upload
    require_relative 'upload/base'
    require_relative 'upload/data'
    require_relative 'upload/row'
    require_relative 'upload/rows'
    require_relative 'upload/processor'
  end
end
