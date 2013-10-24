class CherrypickForPulldownRequest < TransferRequest

  redefine_state_machine do
    # The statemachine for transfer requests is more promiscuous than normal requests, as well
    # as being more concise as it has less states.
    aasm_column :state
    aasm_state :pending
    aasm_state :started
    aasm_state :failed,     :enter => :on_failed
    aasm_state :passed
    aasm_state :cancelled,  :enter => :on_cancelled
    aasm_state :hold
    aasm_initial_state :pending

    aasm_event :hold do
      transitions :to => :hold, :from => [ :pending ]
    end

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
      transitions :to => :cancelled, :from => [:started, :passed]
    end

    aasm_event :cancel_before_started do
      transitions :to => :cancelled, :from => [:pending]
    end

    aasm_event :detach do
      transitions :to => :pending, :from => [:pending, :cancelled]
    end
  end

  def perform_transfer_of_contents
    on_started # Ensures we set the study/project
  end
  private :perform_transfer_of_contents

end
