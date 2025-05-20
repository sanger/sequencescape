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
    detect_upstream_customer_requests.each do |upstream|
      target_labware.racked_tubes.each do |racked_tube|
        pass_and_link_up_requests(racked_tube.tube.receptacle, upstream)
      end
    end
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
  def detect_upstream_customer_requests
    target_labware.in_progress_requests.includes(WorkCompletion::REQUEST_INCLUDES)
  end
end
