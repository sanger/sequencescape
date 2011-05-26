# Specialised implementation of the plate purpose for the initial plate types in the Pulldown pipelines:
# WGS fragmentation plate, SC fragmentation plate, ISC fragmentation plate.
class InitialPulldownPlatePurpose < PlatePurpose
  # The initial plates in the pulldown workflow have a particular behaviour when they transition to 'started': they
  # update the request between the stock plate and the MX library tubes to 'started' too.
  def transition_to(plate, state)
    super
    start_stock_plate_requests(plate) if state == 'started'
  end

  def start_stock_plate_requests(plate)
    plate.parent.requests_as_source.each do |requests|
      requests.update_attributes!(:state => 'started')
    end
  end
  private :start_stock_plate_requests
end
