# frozen_string_literal: true

# Class WorkCompletion::TubeCompletion provides the business logic
# for passing tubes, especially in the Limber pipelines. This has
# been pulled out of WorkCompletion itself to allow for separate behaviour
# for plates and tubes.
#
# @author Genome Research Ltd.
#
class WorkCompletion::TubeRackCompletion < WorkCompletion::LabwareCompletion
  def connect_requests
    detect_upstream_requests.each do |upstream|
      target_labware.racked_tubes.each { |tube| pass_and_link_up_requests(tube.tube.receptacle, upstream) }
    end
    @order_ids.uniq!
  end

  def detect_upstream_requests
    CustomerRequest.includes(WorkCompletion::REQUEST_INCLUDES).where(id: target_labware.aliquots.pluck(:request_id))
  end
end
