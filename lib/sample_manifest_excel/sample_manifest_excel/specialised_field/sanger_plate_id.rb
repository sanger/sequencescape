module SampleManifestExcel
  module SpecialisedField
    class SangerPlateId
      include Base
      include ValueRequired
      
      def value=(sample)
        @value = sample.wells.first.plate.sanger_human_barcode
      end
    end
  end
end