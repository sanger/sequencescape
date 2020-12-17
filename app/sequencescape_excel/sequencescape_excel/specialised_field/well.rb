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
        return if value == asset.try(:map_description)

        errors.add(:sample,
                   'cannot be moved between wells. The well and Sanger sample id columns should not be changed.')
      end
    end
  end
end
