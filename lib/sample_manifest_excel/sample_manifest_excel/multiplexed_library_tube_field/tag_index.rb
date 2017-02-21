module SampleManifestExcel
  module MultiplexedLibraryTubeField
    class TagIndex < Base
      include ValueToInteger
      validates_presence_of :value
    end
  end
end
