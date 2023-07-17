# frozen_string_literal: true
module Qcable::Statemachine # rubocop:todo Style/Documentation
  # rubocop:todo Metrics/MethodLength
  def self.included(base) # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    base.class_eval do
      ## State machine
      ## namespace: true as destroyed clashes with rails, but we can't easily rename the state
      aasm column: :state, whiny_persistence: true, namespace: true, name: 'qc_state' do
        state :created
        state :pending, enter: :on_stamp
        state :failed, enter: :on_failed
        state :passed, enter: :on_passed
        state :available, enter: :on_released
        state :destroyed, enter: :on_destroyed
        state :qc_in_progress, enter: :on_qc
        state :exhausted, enter: :on_used

        initial_state Proc.new { |qcable| qcable.default_state }

        # State Machine events
        event :do_stamp do
          transitions to: :pending, from: [:created]
        end

        event :destroy_labware, allow_automated?: true do
          transitions to: :destroyed, from: %i[pending available]
        end

        event :qc, allow_automated?: true do
          transitions to: :qc_in_progress, from: [:pending]
        end

        event :release do
          transitions to: :available, from: [:pending]
        end

        event :pass do
          transitions to: :passed, from: [:qc_in_progress]
        end

        event :fail do
          transitions to: :failed, from: %i[qc_in_progress pending]
        end

        event :use, allow_automated?: true do
          transitions to: :exhausted, from: [:available]
        end
      end

      # new version of combinable named_scope
      scope :for_state, ->(state) { where(state: state) }

      scope :unavailable, -> { where(state: %i[created pending failed passed destroyed qc_in_progress exhausted]) }
    end
  end

  # rubocop:enable Metrics/MethodLength

  #--
  # These are the callbacks that will be made on entry to a given state.  This allows
  # derived classes to override these and add custom behaviour.  You are advised to call
  # super in any method that you override so that they can be stacked.
  #++
  def on_stamp
    lot.template.stamp_to(asset)
  end

  def default_state
    # We validate the presence of lot, however initial state gets called BEFORE we reach validation
    return :created if lot.nil?

    asset_purpose.default_state.to_sym || :created
  end

  def on_failed; end

  def on_passed; end

  def on_released; end

  def on_destroyed; end

  def on_qc; end

  def on_used; end

  private

  # Only events explicitly declared as automated can be used by
  # transition_to
  def permit_automatic_transition?(event)
    event.options[:allow_automated?]
  end
end
