# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # A well is required if it is a plate manifest.
    # If the value does not match the description of the sample well
    # then it is rejected.
    class Well
      include Base
      include ValueRequired

      validate :check_container

      private

      def check_container
        return if value == sample.wells.first.map.description

        errors.add(:sample, 'You can not move samples between plates or modify barcodes')
      end
    end
  end
end
