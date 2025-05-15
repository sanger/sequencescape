# frozen_string_literal: true
require 'aasm'

#
# Included in submission to add its state-machine
#
# Uses the following states:
# building - Initial state. Indicates the user is preparing the submissions
# pending - The submission has been finalized by the user and is awaiting processing.
#           Entry into this state queues the submission for processing by the {SubmissionBuilderJob}
# processing - The delayed job has picked up the submission and is currently building it
# ready - The submission has been processed and is ready for work
# failed - The {SubmissionBuilderJob} failed and the submission has not been processed
# cancelled - The submission was made in error or is no longer needed. Entry into this
#             state will cancel all requests in the submission.
#
module Submission::StateMachine
  def self.extended(base)
    base.class_eval do
      include AASM
      include InstanceMethods

      configure_state_machine
      configure_named_scopes

      def editable?
        state == 'building'
      end
    end
  end

  module InstanceMethods
    def valid_for_leaving_building_state
      raise ActiveRecord::RecordInvalid, self unless valid?
    end

    def complete_building
      orders.reload.each(&:complete_building)
    end

    def process_submission!
      # Does nothing by default!
    end

    def process_callbacks!
      callbacks.each_value(&:call)
    end

    def callbacks
      @callbacks ||= {}
    end

    def register_callback(key = nil, &block)
      key ||= "k#{@callbacks.size}"
      callbacks[key] = block
    end

    def unprocessed?
      UNPROCESSED_STATES.include?(state)
    end

    def cancellable?
      (pending? || ready?) && requests_cancellable?
    end

    def destroyable?
      building?
    end

    def editable?
      building? || failed?
    end

    def requests_cancellable?
      # Default behaviour, overidden in the model itself
      false
    end

    def broadcast_events
      orders.each(&:generate_broadcast_event)
    end
  end

  def configure_state_machine # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    aasm column: :state, whiny_persistence: true do
      state :building, initial: true, exit: :valid_for_leaving_building_state
      state :pending, after_enter: :queue_submission_builder
      state :processing, enter: :process_submission!, exit: :process_callbacks!
      state :ready, enter: :broadcast_events
      state :failed
      state :cancelled, enter: :cancel_all_requests

      event :built do
        transitions to: :pending, from: [:building], success: :complete_building
      end

      event :process_synchronously do
        transitions to: :processing, from: [:building], success: :complete_building
      end

      event :cancel do
        transitions to: :cancelled, from: %i[pending ready cancelled], guard: :requests_cancellable?
      end

      event :process do
        transitions to: :processing, from: %i[processing failed pending]
      end

      event :ready do
        transitions to: :ready, from: %i[processing failed]
      end

      event :fail do
        transitions to: :failed, from: %i[processing failed pending]
      end
    end
  end

  private :configure_state_machine

  UNPROCESSED_STATES = %w[building pending processing].freeze
  def configure_named_scopes
    scope :unprocessed, -> { where(state: UNPROCESSED_STATES) }
    scope :processed, -> { where(state: %w[ready failed]) }
  end

  private :configure_named_scopes
end
