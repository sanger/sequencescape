# frozen_string_literal: true

module StateChanger
  # The input plate in a pipeline, has the requests
  # coming out of it
  # This version ports the existing behaviour, which essentially blocks
  # the update of transfer request state.
  class InputPlate < StandardPlate
    private

    def associated_requests
      receptacles.flat_map(&:requests_as_source)
    end

    def _receptacles
      labware.wells.includes(:requests_as_source)
    end

    def transfer_requests
      # We don't want to update any transfer requests
      []
    end
  end
end
