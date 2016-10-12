module SampleManifestExcel
  module MultiplexedLibraryTubeField
    class TagGroup < Base
      include TagGroupValidation
      validates_presence_of :value
    end
  end
end