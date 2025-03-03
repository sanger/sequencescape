# frozen_string_literal: true
# This is a module containing the standard statemachine for a request that needs it.
# It provides various callbacks that can be hooked in to by the derived classes.
require 'aasm'

# rubocop:todo Metrics/ModuleLength
module Request::Statemachine
  extend ActiveSupport::Concern
  COMPLETED_STATE = %w[passed failed].freeze
  OPENED_STATE = %w[pending blocked started].freeze
  ACTIVE = %w[passed pending blocked started].freeze
  INACTIVE = %w[failed cancelled].freeze
  SORT_ORDER = %w[pending blocked hold started passed failed cancelled].freeze

  class_methods do
    def redefine_aasm(options = {}, &block)
      destroy_aasm
      aasm(options, &block)
    end

    def destroy_aasm # rubocop:todo Metrics/MethodLength
      # Destroy all evidence of the statemachine we've inherited!  Ugly, but it works!
      old_machine = AASM::StateMachineStore.fetch(self) && AASM::StateMachineStore.fetch(self).machine(:default)
      if old_machine
        old_machine.events.keys.each do |event|
          undef_method(event)
          undef_method(:"#{event}!")
          undef_method(:"#{event}_without_validation!")
          undef_method(:"may_#{event}?")
        end
        old_machine.states.each { |state| undef_method(:"#{state}?") }
      end

      # Wipe out the inherited state machine. Can't use unregister
      # as we still need the state machine on the parent class.
      AASM::StateMachineStore.register(self, true)
    end
  end

  included do
    ## State machine
    aasm column: :state, whiny_persistence: true do
      state :pending, initial: true
      state :started, after_enter: :on_started
      state :failed, after_enter: :on_failed
      state :passed, after_enter: :on_passed
      state :cancelled, after_enter: :on_cancelled
      state :blocked, after_enter: :on_blocked
      state :hold, after_enter: :on_hold

      event :hold do
        transitions to: :hold, from: [:pending]
      end

      # State Machine events
      event :start do
        transitions to: :started, from: %i[pending hold]
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
        transitions to: :cancelled, from: %i[started hold]
      end

      event :return do
        transitions to: :pending, from: %i[failed passed]
      end

      event :cancel_completed do
        transitions to: :cancelled, from: %i[failed passed]
      end

      event :cancel_before_started do
        transitions to: :cancelled, from: %i[pending hold]
      end

      event :submission_cancelled, manual_only?: true do
        transitions to: :cancelled, from: %i[pending cancelled]
      end

      # manual_only prevents the transition being detected by the transition_to methods
      event :fail_from_upstream, manual_only?: true do
        transitions to: :cancelled, from: [:pending]
        transitions to: :failed, from: [:started]
        transitions to: :failed, from: [:passed]
      end

      # Called by {Event} when the evented is a {Request} and the family is fail
      # Can be triggered by NPG, or via the BatchesController::fail page
      # manual_only prevents the transition being detected by the transition_to methods
      event :evented_fail, manual_only?: true do
        transitions to: :failed, from: %i[started passed]
      end

      # Called by {Event} when the evented is a {Request} and the family is pass
      # manual_only prevents the transition being detected by the transition_to methods
      event :evented_pass, manual_only?: true do
        transitions to: :passed, from: %i[started failed]
      end
    end

    scope :for_state, ->(state) { where(state:) }

    scope :completed, -> { where(state: COMPLETED_STATE) }
    scope :pending, -> { where(state: %w[pending blocked]) } # block is a kind of substate of pending }
    scope :opened, -> { where(state: OPENED_STATE) }
    scope :closed, -> { where(state: %w[passed failed cancelled]) }
    scope :not_cancelled, -> { where.not(state: 'cancelled') }
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
        clone.study_id = initial_study_id || aliquot.study_id
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
  deprecate change_decision!:
              'Change decision is being deprecated in favour of retrospective_pass and retrospective_fail!',
            deprecator: ActiveSupport::Deprecation.new('14.53.0', 'Sequencescape')

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
    # Don't transition it again if it's already reached an end state
    return if terminated?

    # Only transition it if *all* upstream requests are failed or cancelled, not just the one we came from.
    return unless upstream_requests.all?(&:terminated?)

    fail_from_upstream!
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
    %w[passed failed cancelled aborted].include?(state)
  end

  def open?
    %w[pending started].include?(state)
  end

  def cancellable?
    %w[pending cancelled].include?(state)
  end
end
# rubocop:enable Metrics/ModuleLength
