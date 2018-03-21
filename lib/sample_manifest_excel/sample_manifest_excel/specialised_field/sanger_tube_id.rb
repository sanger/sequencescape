module SampleManifestExcel
  module SpecialisedField
    ##
    # A required field if it is a tube manifest.
    # No update required.
    # Checked to ensure that it is the same as the sanger human barcode for sample.
    # Not updated
    class SangerTubeId
      include Base
      include ValueRequired

      validate :check_container

      private

      def check_container
        unless value == sample.assets.first.sanger_human_barcode
          errors.add(:sample, 'You can not move samples between tubes or modify barcodes')
        end
      end
    end
  end
end
