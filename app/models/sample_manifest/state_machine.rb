module SampleManifest::StateMachine
  def self.extended(base)
    base.class_eval do
      include AASM

      configure_state_machine
    end
  end

  def configure_state_machine
    aasm_column :state
    aasm_state :pending
    aasm_state :processing
    aasm_state :failed
    aasm_state :completed
    aasm_initial_state :pending

    # State Machine events
    aasm_event :start do
      transitions :to => :processing, :from => [:pending, :failed, :completed, :processing]
    end

    aasm_event :finished do
      transitions :to => :completed, :from => [:processing]
    end

    aasm_event :fail do
      transitions :to => :failed, :from => [:processing]
    end
  end
  private :configure_state_machine

end
