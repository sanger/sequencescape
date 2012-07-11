# This is a module containing the standard statemachine for a request that needs it.
# It provides various callbacks that can be hooked in to by the derived classes.
module Request::Statemachine
  COMPLETED_STATE = [ 'passed', 'failed' ]
  OPENED_STATE    = [ 'pending', 'blocked', 'started' ]
  QUOTA_COUNTED   = [ 'passed', 'pending', 'blocked', 'started' ]
  QUOTA_EXEMPTED  = [ 'failed', 'cancelled', 'aborted' ]

  # Bit of an ugly reproduction of the state machine, but shan't be in here for long.
  TRANSITIONS = {
    'started' => {
      'passed' => :pass!,
      'cancelled' => :cancel!,
      'failed' => :fail!
    },
    'pending' =>{
      'started' => :start!,
      'cancelled' => :cancel_before_started!,
      'hold' => :hold!,
      'blocked' => :block!
    },
    'passed' => {
      'failed' => :change_decision!,
      'pending' => :return!,
      'cancelled' => :cancel_completed!
    },
    'cancelled' => {
      'pending' => :detach!
    },
    'failed' => {
      'passed' => :change_decision!,
      'pending' => :return!,
      'cancelled' => :cancel_completed!
    },
    'hold' => {
      'started' => :start!,
      'pending' => :reset!,
      'cancelled' => :cancel!
    },
    'blocked' => {
      'pending' => :unblock!
    }
  }

  module ClassMethods
    def redefine_state_machine(&block)
      # Destroy all evidence of the statemachine we've inherited!  Ugly, but it works!
      instance_variable_set(:@aasm, nil)
      AASM::StateMachine[self] = AASM::StateMachine.new('')
      instance_eval(&block)
    end

    # Determines the most likely event that should be fired when transitioning between the two states.  If there is
    # only one option then that is what is returned, otherwise an exception is raised.
    def suggested_transition_between(current, target)
      aasm_events.select do |name, event|
        event.transitions_from_state(current.to_sym).any? do |transition|
          transition.to == target.to_sym
        end
      end.tap do |events|
        raise StandardError, "No obvious transition from #{current.inspect} to #{target.inspect}" unless events.size == 1
      end.first.first
    end
  end

  def self.included(base)
    base.class_eval do
      extend ClassMethods
      include Request::BillingStrategy

      ## State machine
      aasm_column :state
      aasm_state :pending
      aasm_state :started,   :enter => :on_started
      aasm_state :failed,    :enter => :on_failed
      aasm_state :passed,    :enter => :on_passed
      aasm_state :cancelled, :enter => :on_cancelled
      aasm_state :blocked,   :enter => :on_blocked
      aasm_state :hold,      :enter => :on_hold
      aasm_initial_state :pending

      aasm_event :hold do
        transitions :to => :hold, :from => [ :pending ]
      end

      # State Machine events
      aasm_event :start do
        transitions :to => :started, :from => [:pending, :hold]
      end

      aasm_event :pass do
        transitions :to => :passed, :from => [:started], :on_transition => :charge_to_project
      end

      aasm_event :fail do
        transitions :to => :failed, :from => [:started], :on_transition => :charge_internally
      end

      aasm_event :change_decision do
        transitions :to => :failed, :from => [:passed],  :on_transition => :refund_project
        transitions :to => :passed, :from => [:failed], :on_transition => :charge_to_project
      end

      aasm_event :block do
        transitions :to => :blocked, :from => [:pending]
      end

      aasm_event :unblock do
        transitions :to => :pending, :from => [:blocked]
      end

      aasm_event :detach do
        transitions :to => :pending, :from => [:cancelled]
      end

      aasm_event :reset do
        transitions :to => :pending, :from => [:hold]
      end

      aasm_event :cancel do
        transitions :to => :cancelled, :from => [:started, :hold]
      end

      aasm_event :return do
        transitions :to => :pending, :from => [:failed, :passed]
      end

      aasm_event :cancel_completed do
        transitions :to => :cancelled, :from => [:failed, :passed]
      end

      aasm_event :cancel_from_upstream do
        transitions :to => :cancelled, :from => [:pending]
      end

      aasm_event :cancel_before_started do
        transitions :to => :cancelled, :from => [:pending]
      end

      after_save :release_unneeded_quotas!

      # new version of combinable named_scope
      named_scope :for_state, lambda { |state| { :conditions => { :state => state } } }

      named_scope :completed, :conditions => {:state => COMPLETED_STATE}
      named_scope :passed, :conditions => {:state => "passed"}
      named_scope :failed, :conditions => {:state => "failed"}
      named_scope :pipeline_pending, :conditions => {:state => "pending"} #  we don't want the blocked one here
      named_scope :pending, :conditions => {:state => ["pending", "blocked"]} # block is a kind of substate of pending

      named_scope :started, :conditions => {:state => "started"}
      named_scope :cancelled, :conditions => {:state => "cancelled"}
      named_scope :aborted, :conditions => {:state => "aborted"}

      named_scope :open, :conditions => {:state => OPENED_STATE}
      named_scope :closed, :conditions => {:state => ["passed", "failed", "cancelled", "aborted"]}
      named_scope :quota_counted, :conditions => {:state => QUOTA_COUNTED}
      named_scope :quota_exempted, :conditions => {:state => QUOTA_EXEMPTED}
      named_scope :hold, :conditions => {:state => "hold"}
    end
  end

  def transition_to(target_state)
    method = transition_method_to(target_state)
    raise AASM::InvalidTransition, "Can not transition from #{state} to #{target_state}" if method.nil?
    self.send(method)
  end

  def transition_method_to(target_state)
    TRANSITIONS[state][target_state]
  end
  private :transition_method_to
  #--
  # These are the callbacks that will be made on entry to a given state.  This allows
  # derived classes to override these and add custom behaviour.  You are advised to call
  # super in any method that you override so that they can be stacked.
  #++

  # On starting a request the aliquots are copied from the source asset to the target
  # and updated with the project and study information from the request itself.
  def on_started
    target_asset.aliquots << asset.aliquots.map do |aliquot|
      aliquot.clone.tap do |clone|
        clone.study_id   = initial_study_id   || aliquot.study_id
        clone.project_id = initial_project_id || aliquot.project_id
      end
    end
  end

  def on_failed

  end

  def release_unneeded_quotas!
    self.request_quotas(true).destroy_all unless quota_counted?
  end

  def on_passed

  end

  def on_cancelled

  end

  def on_blocked

  end

  def on_hold

  end

  def quota_counted?
    return QUOTA_COUNTED.include?(state)
  end

  def finished?
    self.passed? || self.failed?
  end

  def closed?
    ["passed", "failed", "cancelled", "aborted"].include?(self.state)
  end

  def open?
    ["pending", "started"].include?(self.state)
  end

  def transition_to(target_state)
    send("#{self.class.suggested_transition_between(self.state, target_state)}!")
  end
end
