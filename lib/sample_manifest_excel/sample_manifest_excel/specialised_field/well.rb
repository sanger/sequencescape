module SampleManifestExcel
  module SpecialisedField
    class Well
      include Base
      include ValueRequired

      validate :check_container

    private

      def check_container
        unless value == sample.wells.first.map.description
          errors.add(:sample, 'You can not move samples between plates or modify barcodes')
        end
      end
      
    end
  end
end