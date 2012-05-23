# Every request "moving" an asset from somewhere to somewhere else without really transforming it
# (chemically) as, cherrypicking, pooling, spreading on the floor etc
class TransferRequest < Request
  # Destroy all evidence of the statemachine we've inherited!  Ugly, but it works!
  instance_variable_set(:@aasm, nil)
  AASM::StateMachine[self] = AASM::StateMachine.new('')

  # The statemachine for transfer requests is more promiscuous than normal requests, as well
  # as being more concise as it has less states.
  aasm_column :state
  aasm_state :pending
  aasm_state :started
  aasm_state :failed
  aasm_state :passed
  aasm_state :cancelled
  aasm_initial_state :pending

  # State Machine events
  aasm_event :start do
    transitions :to => :started, :from => [:pending]
  end

  aasm_event :pass do
    transitions :to => :passed, :from => [:pending, :started, :failed]
  end

  aasm_event :fail do
    transitions :to => :failed, :from => [:pending, :started, :passed]
  end

  aasm_event :cancel do
    transitions :to => :cancelled, :from => [:started]
  end

  aasm_event :detach do
    transitions :to => :pending, :from => [:pending]
  end

  # Ensure that the source and the target assets are not the same, otherwise bad things will happen!
  validate do |record|
    if record.asset.present? and record.asset == record.target_asset
      record.errors.add(:asset, 'cannot be the same as the target')
      record.errors.add(:target_asset, 'cannot be the same as the source')
    end
  end

  before_create(:add_request_type)
  def add_request_type
    self.request_type ||= RequestType.transfer
  end
  private :add_request_type

  after_create(:perform_transfer_of_contents)

  def perform_transfer_of_contents
    target_asset.aliquots << asset.aliquots.map(&:clone) unless asset.failed? or asset.cancelled?
  end
  private :perform_transfer_of_contents
end
