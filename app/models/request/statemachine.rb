#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2013,2015 Genome Research Ltd.
# This is a module containing the standard statemachine for a request that needs it.
# It provides various callbacks that can be hooked in to by the derived classes.
module Request::Statemachine
  COMPLETED_STATE = [ 'passed', 'failed' ]
  OPENED_STATE    = [ 'pending', 'blocked', 'started' ]
  ACTIVE = QUOTA_COUNTED   = [ 'passed', 'pending', 'blocked', 'started' ]
  QUOTA_EXEMPTED  = [ 'failed', 'cancelled', 'aborted' ]

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

      ## State machine
      aasm_column :state
      aasm_state :pending
      aasm_state :started,   :after_enter => :on_started
      aasm_state :failed,    :after_enter => :on_failed
      aasm_state :passed,    :after_enter => :on_passed
      aasm_state :cancelled, :after_enter => :on_cancelled
      aasm_state :blocked,   :after_enter => :on_blocked
      aasm_state :hold,      :after_enter => :on_hold
      aasm_initial_state :pending

      aasm_event :hold do
        transitions :to => :hold, :from => [ :pending ]
      end

      # State Machine events
      aasm_event :start do
        transitions :to => :started, :from => [:pending, :hold]
      end

      aasm_event :pass do
        transitions :to => :passed, :from => [:started]
      end

      aasm_event :fail do
        transitions :to => :failed, :from => [:started]
      end

      aasm_event :retrospective_pass do
        transitions :to => :passed, :from => [:failed]
      end

      aasm_event :retrospective_fail do
        transitions :to => :failed, :from => [:passed]
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

      aasm_event :fail_from_upstream do
        transitions :to => :cancelled, :from => [:pending]
        transitions :to => :failed,    :from => [:started]
        transitions :to => :failed,    :from => [:passed]
      end

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
      named_scope :hold, :conditions => {:state => "hold"}
    end
  end

  #--
  # These are the callbacks that will be made on entry to a given state.  This allows
  # derived classes to override these and add custom behaviour.  You are advised to call
  # super in any method that you override so that they can be stacked.
  #++

  # On starting a request the aliquots are copied from the source asset to the target
  # and updated with the project and study information from the request itself.
  def on_started
    transfer_aliquots
  end

  def transfer_aliquots
    target_asset.aliquots << asset.aliquots.map do |aliquot|
      aliquot.clone.tap do |clone|
        clone.study_id   = initial_study_id   || aliquot.study_id
        clone.project_id = initial_project_id || aliquot.project_id
      end
    end
  end

  def change_decision!
    Rails.logger.warn('Change decision is being deprecated in favour of retrospective_pass and retrospective_fail!')
    return retrospective_fail! if passed?
    return retrospective_pass! if failed?
    raise StandardError, "Can only use change decision on passed or failed requests"
  end
  deprecate :change_decision!

  def on_failed

  end

  def on_passed

  end

  def on_cancelled

  end

  def on_blocked

  end

  def on_hold

  end

  def failed_upstream!
    fail_from_upstream! unless failed?
  end

  def failed_downstream!
    # Do nothing by default
  end

  def finished?
    self.passed? || self.failed?
  end

  def terminated?
    self.failed? || self.cancelled?
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
