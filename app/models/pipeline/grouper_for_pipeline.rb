# frozen_string_literal: true
# Some {Pipeline pipelines} group requests together in the inbox, such that all requests
# in a submission or plate MUST be selected together
# This takes the selected checkboxes and splits the information back out to the
# individual requests.
# This class is the base class, the actual behaviour is on the various subclasses
class Pipeline::GrouperForPipeline
  delegate :requests, to: :@pipeline

  def initialize(pipeline)
    @pipeline = pipeline
  end

  def base_scope
    requests.order(:id).ready_in_storage.full_inbox.select('requests.*')
  end

  def all(_)
    # Piplelines with grouping functionality should use a specific grouper
    raise 'Not implimented for this pipeline'
  end
end
