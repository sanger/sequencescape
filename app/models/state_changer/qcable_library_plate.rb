# frozen_string_literal: true

module StateChanger
  # State on QcableLibraryPlatePurpose is held by the QcAable, and isn't
  # actually updated as part of the QC pipeline. Instead the state changer
  # is purely concerned with applying library information to the plate.
  # @note This pipeline is no longer actively used. We can likely remove this
  # as part of: https://github.com/sanger/gatekeeper/issues/100 - Closing the gate(keeper)
  class QcableLibraryPlate < StateChanger::Base
    LIBRARY_TYPE = 'QA1'
    INSERT_SIZE = Aliquot::InsertSize.new(100, 100).freeze

    # Updates the state of the labware to the target state.  The basic implementation does this by updating
    # all of the TransferRequest instances to the state specified.  If contents is blank then the change is assumed to
    # relate to all wells of the plate, otherwise only the selected ones are updated.
    # @return [Void]
    def update_labware_state
      assign_library_information_to_wells
    end

    private

    # Ensure that the library information within the aliquots of the well is correct.
    def assign_library_information_to_wells
      labware.wells.each do |well|
        well.aliquots.each do |aliquot|
          aliquot.library ||= well
          aliquot.library_type ||= LIBRARY_TYPE
          aliquot.insert_size ||= INSERT_SIZE
          aliquot.save!
        end
      end
    end
  end
end
