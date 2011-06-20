# Specialised implementation of the plate purpose for the initial plate types in the Pulldown pipelines:
# WGS fragmentation plate, SC fragmentation plate, ISC fragmentation plate.
class InitialPulldownPlatePurpose < PlatePurpose
  # The initial plates in the pulldown workflow have a particular behaviour when they transition to 'started': they
  # update the request between the stock plate and the MX library tubes to 'started' too.
  def transition_to(plate, state)
    super
    start_stock_plate_requests(plate) if state == 'started'
  end

  # Find all of the non-transfer requests from the wells on the stock plate and update them to started.  Really
  # we should only have one instance of this class associated to a particular stock plate but we have to be 
  # careful.
  def start_stock_plate_requests(plate)
    plate.parent.wells.map do |well|
      well.requests_as_source.where_is_not_a?(TransferRequest)
    end.flatten.each do |request|
      request.update_attributes!(:state => 'started')
    end
  end
  private :start_stock_plate_requests
end
