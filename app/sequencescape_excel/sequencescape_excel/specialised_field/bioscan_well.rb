# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    # BioscanWell
    # Specialised field to link validations from bioscan control type
    class BioscanWell
      include Base
      include ValueRequired

      validate :check_container

      private

      def check_container
        return if value == asset.try(:map_description)

        errors.add(
          :sample,
          'cannot be moved between wells. The well and Sanger sample id columns should not be changed.'
        )
      end
    end
  end
end
