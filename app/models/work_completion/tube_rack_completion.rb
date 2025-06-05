# frozen_string_literal: true

# Class WorkCompletion::TubeRackCompletion provides the business logic
# for passing tubes within a tube rack, especially in the Limber pipelines. This has
# been pulled out of WorkCompletion itself to allow for separate behaviour
# for tube racks.
#
# @author Genome Research Ltd.
#
class WorkCompletion::TubeRackCompletion < WorkCompletion::LabwareCompletion
  # Connects upstream requests to the target labware's racked tubes.
  #
  # Iterates through each upstream request and links it to the receptacle
  # of each tube in the target labware's racked tubes.
  #
  # @return [void]
  #
  # @example
  #   connect_requests
  def connect_requests
    target_tubes.each do |target_tube|
      detect_upstream_requests.each { |upstream| pass_and_link_up_requests(target_tube.tube.receptacle, upstream) }
    end
  end

  # Retrieves the target tubes associated with the target labware.
  #
  # This method fetches the tubes that are racked within the target labware (i.e., tube rack),
  # including their associated aliquots and requests. It filters the tubes
  # based on the submission IDs of the requests.
  #
  # @note This method is similar to the `target_wells` method in
  #   `WorkCompletion::PlateCompletion`,
  #
  # @return [ActiveRecord::Relation] A collection of target tubes.
  #
  # @example
  #   target_tubes
  #   # => [#<Tube id: 1>, #<Tube id: 2>]
  def target_tubes
    @target_tubes ||=
      target_labware
        .racked_tubes
        .includes(tube: { aliquots: { request: WorkCompletion::REQUEST_INCLUDES } })
        .where(requests: { submission_id: submission_ids })
  end

  # Detects upstream customer requests associated with the target labware.
  #
  # Queries the database for customer requests linked to the aliquots
  # of the target labware.
  #
  # @return [ActiveRecord::Relation] A collection of customer requests.
  #
  # @example
  #   detect_upstream_requests
  #   # => [#<CustomerRequest id: 1>, #<CustomerRequest id: 2>]
  def detect_upstream_requests
    target_labware.in_progress_requests.includes(WorkCompletion::REQUEST_INCLUDES)
  end
end
