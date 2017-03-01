module SampleManifestExcel
  module SpecialisedField
    class DonorId
      include Base
      include ValueRequired
      include SangerSampleIdValue
    end
  end
end