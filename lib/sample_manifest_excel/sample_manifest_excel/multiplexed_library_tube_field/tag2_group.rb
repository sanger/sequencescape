module SampleManifestExcel
  module MultiplexedLibraryTubeField
    class Tag2Group < MultiplexedLibraryTubeField::Base
      include TagGroupValidation
    end
  end
end