module SampleManifestExcel
  module SpecialisedField
    class SangerSampleId
      include Base
      include ValueRequired
      
      include SangerSampleIdValue
    end
  end
end