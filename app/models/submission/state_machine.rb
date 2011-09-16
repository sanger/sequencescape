module Submission::StateMachine
  def self.extended(base)
    base.class_eval do
      include AASM
      include InstanceMethods

      configure_state_machine
      configure_named_scopes
    end
  end

  module InstanceMethods
    # TODO[xxx]: This should be a guard but what the heck ...
    def left_building_state?
      not self.building? or !!@leaving_building_state
    end

    def valid_for_leaving_building_state
      @leaving_building_state = true
      raise ActiveRecord::RecordInvalid, self unless valid?
    ensure
      @leaving_building_state = false
    end
    # TODO[xxx]: ... to here

    def complete_building
      orders.all?(&:complete_building)

    end

    def process_submission!
      # Does nothing by default!
    end
    def unprocessed?
      UnprocessedStates.include?(state)
    end
  end

  def configure_state_machine
    aasm_column :state
    aasm_initial_state :building
    aasm_state :building, :exit => :valid_for_leaving_building_state
    aasm_state :pending, :enter => :complete_building
    aasm_state :processing, :enter => :process_submission!
    aasm_state :ready
    aasm_state :failed

    aasm_event :built do
      transitions :to => :pending, :from => [ :building ]
    end

    aasm_event :process do
      transitions :to => :processing, :from => [:processing, :failed, :pending]
    end

    aasm_event :ready do
      transitions :to => :ready, :from => [:processing, :failed]
    end

    aasm_event :fail do
      transitions :to => :failed, :from => [:processing, :failed, :pending]
    end
  end
  private :configure_state_machine

  UnprocessedStates = ["building", "pending", "processing"]
  def configure_named_scopes
    named_scope :unprocessed, :conditions => {:state => UnprocessedStates}
    named_scope :processed, :conditions => {:state => ["ready", "failed"]}
  end

  private :configure_named_scopes
end
