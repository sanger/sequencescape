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

    def update_transfer_requests(*args)
      # Does nothing, we'll do it in a moment!
    end
  end
end
