module PlatePurpose::Initial
  def self.included(base)
    base.class_eval do
      include PlatePurpose::WorksOnLibraryRequests
    end
  end

  # Initial plates in the pulldown pipelines change the state of the pulldown requests they are being
  # created for to exactly the same state.
  def transition_to(plate, state, contents = nil)
    super
    start_pulldown_library_requests(plate)
  end

  # Ensure that the pulldown library creation request is started
  def start_pulldown_library_requests(plate)
    each_well_and_its_library_request(plate) do |_, request|
      request.start! if request.pending?
    end
  end
  private :start_pulldown_library_requests
end