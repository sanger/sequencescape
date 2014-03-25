module Qcable::Statemachine

  module ClassMethods
    # A little more sensitive than the request state machine
    def suggested_transition_between(current, target)
      aasm_events.select do |name, event|

        event.transitions_from_state(current.to_sym).any? do |transition|
          transition.options[:allow_automated?] && transition.to == target.to_sym
        end
      end.tap do |events|
        raise StandardError, "No automated transition from #{current.inspect} to #{target.inspect}" unless events.size == 1
      end.first.first
    end
  end

  def self.included(base)
    base.class_eval do
      extend ClassMethods

      ## State machine
      aasm_column :state
      aasm_state :created
      aasm_state :pending,        :enter => :on_stamp
      aasm_state :failed,         :enter => :on_failed
      aasm_state :passed,         :enter => :on_passed
      aasm_state :available,     :enter => :on_released
      aasm_state :destroyed,      :enter => :on_destroyed
      aasm_state :qc_in_progress, :enter => :on_qc
      aasm_state :exhausted,      :enter => :on_used

      aasm_initial_state :created

      aasm_event :hold do
        transitions :to => :hold, :from => [ :pending ]
      end

      # State Machine events
      aasm_event :do_stamp do
        transitions :to => :pending, :from => [ :created ]
      end

      aasm_event :destroy do
        transitions :to => :destroyed, :from => [:pending,:available], :allow_automated? => true
      end

      aasm_event :qc do
        transitions :to => :qc_in_progress, :from => [:pending]
      end

      aasm_event :release do
        transitions :to => :available, :from => [:pending]
      end

      aasm_event :pass do
        transitions :to => :passed, :from => [:qc_in_progress]
      end

      aasm_event :fail do
        transitions :to => :failed, :from => [:qc_in_progress,:pending]
      end

      aasm_event :use do
        transitions :to => :exhausted, :from => [:available]
      end

      # new version of combinable named_scope
      named_scope :for_state, lambda { |state| { :conditions => { :state => state } } }

      named_scope :available, :conditions => {:state => :available}
      named_scope :unavailable, :conditions => {:state => [:created,:pending,:failed,:passed,:destroyed,:qc_in_progress,:exhausted]}

    end
  end

  #--
  # These are the callbacks that will be made on entry to a given state.  This allows
  # derived classes to override these and add custom behaviour.  You are advised to call
  # super in any method that you override so that they can be stacked.
  #++
  def on_stamp
    lot.template.stamp_to(asset)
  end

  def on_failed; end
  def on_passed; end
  def on_released; end
  def on_destroyed; end
  def on_qc; end
  def on_used; end

  def transition_to(target_state)
    send("#{self.class.suggested_transition_between(self.state, target_state)}!")
  end

end
