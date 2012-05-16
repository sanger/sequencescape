# Every request "moving" an asset from somewhere to somewhere else without really transforming it
# (chemically) as, cherrypicking, pooling, spreading on the floor etc
class TransferRequest < Request
  # The statemachine for transfer requests is more promiscuous than normal requests, as well
  # as being more concise as it has less states.
  state_machine :state, :initial => :pending do
    # State Machine events
    event :start do
      transition :to => :started, :from => :pending
    end

    event :pass do
      transition :to => :passed, :from => [:pending, :started, :failed]
    end

    event :fail do
      transition :to => :failed, :from => [:pending, :started, :failed]
    end

    event :cancel do
      transition :to => :cancelled, :from => :started
    end

    event :detach do
      transition :to => :pending, :from => :pending
    end

  end


  # Ensure that the source and the target assets are not the same, otherwise bad things will happen!
  validate do |record|
    if record.asset.present? and record.asset == record.target_asset
      record.errors.add(:asset, 'cannot be the same as the target')
      record.errors.add(:target_asset, 'cannot be the same as the source')
    end
  end

  after_create(:perform_transfer_of_contents)

  def perform_transfer_of_contents
    target_asset.aliquots << asset.aliquots.map(&:clone) unless asset.failed? or asset.cancelled?
  end
  private :perform_transfer_of_contents
end
