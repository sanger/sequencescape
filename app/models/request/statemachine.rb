# This is a module containing the standard statemachine for a request that needs it.
# It provides various callbacks that can be hooked in to by the derived classes.
require 'aasm'

module Request::Statemachine
  COMPLETED_STATE = %w[passed failed]
  OPENED_STATE    = %w[pending blocked started]
  ACTIVE = %w(passed pending blocked started)
  INACTIVE = %w[failed cancelled]
  SORT_ORDER = %w[pending blocked hold started passed failed cancelled]

  module ClassMethods
    def redefine_aasm(options = {}, &block)
      destroy_aasm
      aasm(options, &block)
    end

    def destroy_aasm
      # Destroy all evidence of the statemachine we've inherited!  Ugly, but it works!
      old_machine = AASM::StateMachineStore.fetch(self) && AASM::StateMachineStore.fetch(self).machine(:default)
      if old_machine
        old_machine.events.keys.each do |event|
          undef_method(event);
          undef_method(:"#{event}!");
          undef_method(:"may_#{event}?")
        end
        old_machine.states.each do |state|
          undef_method(:"#{state}?")
        end
      end
      # Wipe out the inherited state machine. Can't use unregister
      # as we still need the state machine on the parent class.
      AASM::StateMachineStore.register(self, true)
    end
  end

  def self.included(base)
    base.class_eval do
      extend ClassMethods

      ## State machine
      aasm column: :state, whiny_persistence: true do
        state :pending,   initial: true
        state :started,   after_enter: :on_started
        state :failed,    after_enter: :on_failed
        state :passed,    after_enter: :on_passed
        state :cancelled, after_enter: :on_cancelled
        state :blocked,   after_enter: :on_blocked
        state :hold,      after_enter: :on_hold

        event :hold do
          transitions to: :hold, from: [:pending]
        end

        # State Machine events
        event :start do
          transitions to: :started, from: [:pending, :hold]
        end

        event :pass do
          transitions to: :passed, from: [:started]
        end

        event :fail do
          transitions to: :failed, from: [:started]
        end

        event :retrospective_pass do
          transitions to: :passed, from: [:failed]
        end

        event :retrospective_fail do
          transitions to: :failed, from: [:passed]
        end

        event :block do
          transitions to: :blocked, from: [:pending]
        end

        event :unblock do
          transitions to: :pending, from: [:blocked]
        end

        event :detach do
          transitions to: :pending, from: [:cancelled]
        end

        event :reset do
          transitions to: :pending, from: [:hold]
        end

        event :cancel do
          transitions to: :cancelled, from: [:started, :hold]
        end

        event :return do
          transitions to: :pending, from: [:failed, :passed]
        end

        event :cancel_completed do
          transitions to: :cancelled, from: [:failed, :passed]
        end

        event :cancel_from_upstream, manual_only?: true do
          transitions to: :cancelled, from: [:pending]
        end

        event :cancel_before_started do
          transitions to: :cancelled, from: [:pending, :hold]
        end

        event :submission_cancelled, manual_only?: true do
          transitions to: :cancelled, from: [:pending, :cancelled]
        end

        event :fail_from_upstream, manual_only?: true do
          transitions to: :cancelled, from: [:pending]
          transitions to: :failed,    from: [:started]
          transitions to: :failed,    from: [:passed]
        end
      end

      scope :for_state, ->(state) { where(state: state) }

      scope :completed,        -> { where(state: COMPLETED_STATE) }

      scope :pipeline_pending, -> { where(state: 'pending') } #  we don't want the blocked one here }
      scope :pending,          -> { where(state: %w[pending blocked]) } # block is a kind of substate of pending }

      scope :started,          -> { where(state: 'started') }
      scope :cancelled,        -> { where(state: 'cancelled') }

      scope :opened,           -> { where(state: OPENED_STATE) }
      scope :closed,           -> { where(state: %w[passed failed cancelled]) }
    end
  end

  #--
  # These are the callbacks that will be made on entry to a given state.  This allows
  # derived classes to override these and add custom behaviour.  You are advised to call
  # super in any method that you override so that they can be stacked.
  #++

  # Default behaviour on started is to do nothing.
  def on_started
    # Some subclasses may call transfer_aliquots below.
  end

  # Aliquots are copied from the source asset to the target and updated with the
  # project and study information from the request itself.
  def transfer_aliquots
    target_asset.aliquots << asset.aliquots.map do |aliquot|
      aliquot.dup.tap do |clone|
        clone.study_id   = initial_study_id   || aliquot.study_id
        clone.project_id = initial_project_id || aliquot.project_id
      end
    end
  end

  #
  # Toggles passed request to failed, and failed requests to pass.
  # @deprecated Favour retrospective_pass and retrospective_fail! instead.
  #   It is incredibly unlikely that you wish to arbitrarily toggle the state of a request
  #   And instead you probably have an explicit target state in mind. Use that instead.
  # @return [void]
  #
  def change_decision!
    return retrospective_fail! if passed?
    return retrospective_pass! if failed?

    raise StandardError, 'Can only use change decision on passed or failed requests'
  end
  deprecate change_decision!: 'Change decision is being deprecated in favour of retrospective_pass and retrospective_fail!'

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
    passed? || failed?
  end

  def terminated?
    failed? || cancelled?
  end

  def closed?
    %w(passed failed cancelled aborted).include?(state)
  end

  def open?
    %w(pending started).include?(state)
  end

  def cancellable?
    %w(pending cancelled).include?(state)
  end

  def transition_to(target_state)
    aasm.fire!(suggested_transition_to(target_state))
  end

  private

  # Determines the most likely event that should be fired when transitioning between the two states.  If there is
  # only one option then that is what is returned, otherwise an exception is raised.
  def suggested_transition_to(target)
    valid_events = aasm.events(permitted: true).select { |e| !e.options[:manual_only?] && e.transitions_to_state?(target.to_sym) }
    raise StandardError, "No obvious transition from #{state.inspect} to #{target.inspect}" unless valid_events.size == 1

    valid_events.first.name
  end
end
