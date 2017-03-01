module SampleManifestExcel
  module SpecialisedField
    class DonorId2
      include Base
      include ValueRequired
      include SangerSampleIdValue
    end
  end
end