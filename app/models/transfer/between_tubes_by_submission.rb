class Transfer::BetweenTubesBySubmission < Transfer
  include TransfersToKnownDestination

  belongs_to :source, :polymorphic => true

  before_validation :ensure_destination_setup
  def ensure_destination_setup
    self.destination = source.stock_wells.flatten.first.requests_as_source.detect do |request|
      request.target_tube
    end.try(:target_tube)
  end
  private :ensure_destination_setup

  after_create :update_destination_tube_name
  def update_destination_tube_name
    destination.update_attributes!(:name => source.name_for_child_tube)
  end
  private :update_destination_tube_name

  def each_transfer(&block)
    yield(source, destination)
  end
  private :each_transfer

  def request_type_between(ignored_a, ignored_b)
    destination.transfer_request_type_from(source)
  end
  private :request_type_between
end
