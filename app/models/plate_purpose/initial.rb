module PlatePurpose::Initial
  def self.included(base)
    base.class_eval do
      include PlatePurpose::WorksOnLibraryRequests
    end
  end

  # Ensure that the pulldown library creation request is started
  # @note PlatePurpose defines its own version of this method, which should
  #       be more versatile and performant. This has been left to ensure
  #       we don't introduce unexpected behaviour changes.
  def broadcast_library_start(plate, user)
    orders = Set.new
    each_well_and_its_library_request(plate) do |_, request|
      orders << request.order_id if request.pending?
    end
    generate_events_for(plate, orders, user)
  end
  private :broadcast_library_start
end
