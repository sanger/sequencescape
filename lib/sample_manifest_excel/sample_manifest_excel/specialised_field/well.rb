module SampleManifestExcel
  module SpecialisedField
    class Well
      include Base
      include ValueRequired

      def value=(sample)
        @value = sample.wells.first.map.description
      end
    end
  end
end