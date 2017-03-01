module SampleManifestExcel
  module SpecialisedField
    class SangerTubeId
      include Base
      include ValueRequired

      def value=(sample)
        @value = sample.assets.first.sanger_human_barcode
      end
    end
  end
end