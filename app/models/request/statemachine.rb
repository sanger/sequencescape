#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2013,2014,2015,2016 Genome Research Ltd.

# This is a module containing the standard statemachine for a request that needs it.
# It provides various callbacks that can be hooked in to by the derived classes.
require 'aasm'

module Request::Statemachine
  COMPLETED_STATE = [ 'passed', 'failed' ]
  OPENED_STATE    = [ 'pending', 'blocked', 'started' ]
  ACTIVE = QUOTA_COUNTED   = [ 'passed', 'pending', 'blocked', 'started' ]
  INACTIVE = QUOTA_EXEMPTED  = [ 'failed', 'cancelled', 'aborted' ]

  module ClassMethods
    def redefine_aasm(options={},&block)
      # Destroy all evidence of the statemachine we've inherited!  Ugly, but it works!
      AASM::StateMachine[self][:default].events.keys.each {|event| undef_method(event); undef_method(:"#{event}!"); undef_method(:"may_#{event}?") }
      AASM::StateMachine[self] = {}
      aasm(options,&block)
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
      aasm :column => :state do

        state :pending,   :initial => true
        state :started,   :after_enter => :on_started
        state :failed,    :after_enter => :on_failed
        state :passed,    :after_enter => :on_passed
        state :cancelled, :after_enter => :on_cancelled
        state :blocked,   :after_enter => :on_blocked
        state :hold,      :after_enter => :on_hold


        event :hold do
          transitions :to => :hold, :from => [ :pending ]
        end

        # State Machine events
        event :start do
          transitions :to => :started, :from => [:pending, :hold]
        end

        event :pass do
          transitions :to => :passed, :from => [:started]
        end

        event :fail do
          transitions :to => :failed, :from => [:started]
        end

        event :retrospective_pass do
          transitions :to => :passed, :from => [:failed]
        end

        event :retrospective_fail do
          transitions :to => :failed, :from => [:passed]
        end

        event :block do
          transitions :to => :blocked, :from => [:pending]
        end

        event :unblock do
          transitions :to => :pending, :from => [:blocked]
        end

        event :detach do
          transitions :to => :pending, :from => [:cancelled]
        end

        event :reset do
          transitions :to => :pending, :from => [:hold]
        end

        event :cancel do
          transitions :to => :cancelled, :from => [:started, :hold]
        end

        event :return do
          transitions :to => :pending, :from => [:failed, :passed]
        end

        event :cancel_completed do
          transitions :to => :cancelled, :from => [:failed, :passed]
        end

        event :cancel_from_upstream do
          transitions :to => :cancelled, :from => [:pending]
        end

        event :cancel_before_started do
          transitions :to => :cancelled, :from => [:pending, :hold]
        end

        event :submission_cancelled do
          transitions :to => :cancelled, :from => [:pending,:cancelled]
        end

        event :fail_from_upstream do
          transitions :to => :cancelled, :from => [:pending]
          transitions :to => :failed,    :from => [:started]
          transitions :to => :failed,    :from => [:passed]
        end

      end

     scope :for_state, ->(state) { where(:state => state) }

     scope :completed,        -> { where(:state => COMPLETED_STATE) }

     scope :pipeline_pending, -> { where(:state => "pending") } #  we don't want the blocked one here }
     scope :pending,          -> { where(:state => ["pending", "blocked"]) } # block is a kind of substate of pending }

     scope :started,          -> { where(:state => "started") }
     scope :cancelled,        -> { where(:state => "cancelled") }
     scope :aborted,          -> { where(:state => "aborted") }

     scope :opened,           -> { where(:state => OPENED_STATE) }
     scope :closed,           -> { where(:state => ["passed", "failed", "cancelled", "aborted"]) }

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
      aliquot.dup.tap do |clone|
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

  def cancellable?
    ["pending", "cancelled"].include?(self.state)
  end

  def transition_to(target_state)
    send("#{self.class.suggested_transition_between(self.state, target_state)}!")
  end
end
