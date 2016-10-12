module SampleManifestExcel
  module MultiplexedLibraryTubeField
    class InsertSizeTo < Base
      
      validates_presence_of :value
      validates_numericality_of :value, greater_than: 0
    end
  end
end