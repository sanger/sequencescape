# frozen_string_literal: true

module StateChanger
  # The input plate in a pipeline, has the requests
  # coming out of it
  # This version is for use when the plate is an additional start point that
  # in the middle of a workflow
  class AdditionalInputPlate < StandardPlate
    # Maps target state of the labware to the state of associated requests.
    # When the labware is failed the associated requests will be failed.
    # When the labware is passed the associated requests will be started.
    # All other transitions will be ignored.
    self.map_target_state_to_associated_request_state = { 'failed' => 'failed' }

    private

    def associated_requests
      # prefer source requests if present as should be the current requests
      source_requests = receptacles.flat_map(&:requests_as_source).uniq

      # fall back to aliquot requests in case of no current submission on the plate
      # (may trigger a retrospective fail if failing a well)
      aliquot_requests = receptacles.flat_map(&:aliquot_requests).uniq

      source_requests.presence || aliquot_requests
    end

    def _receptacles
      labware.wells.includes(
        :requests_as_source,
        :aliquot_requests,
        transfer_requests_as_target: [
          { associated_requests: %i[request_type request_events] },
          :target_aliquot_requests
        ]
      )
    end

    def transfer_requests
      # We don't want to update transfer requests if there are is no parent
      # i.e. this labware is an additional start point so might not have any
      labware.ancestors.count.zero? ? [] : receptacles.flat_map(&:transfer_requests_as_target)
    end
  end
end
