# frozen_string_literal: true

module StateChanger
  # The initial plate in a pipeline.
  # This version ports the existing behaviour, which essentially blocks
  # the update of transfer request state.
  class InputPlate < StandardPlate
    private

    # The requests that we're going to be failing are based on the requests coming out of the
    # wells, and the wells themselves, for stock plates.
    def fail_request_details_for
      receptacles.each do |well|
        submission_ids = well.requests_as_source.map(&:submission_id)
        yield(submission_ids, [well.id]) unless submission_ids.empty?
      end
    end

    def update_transfer_requests(*args)
      # Does nothing, we'll do it in a moment!
    end
  end
end
