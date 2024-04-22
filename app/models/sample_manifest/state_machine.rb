# frozen_string_literal: true
require 'aasm'

module SampleManifest::StateMachine
  def self.extended(base)
    base.class_eval do
      include AASM

      configure_state_machine
    end
  end

  def configure_state_machine
    aasm column: :state, whiny_persistence: true do
      state :pending, initial: true
      state :processing
      state :failed
      state :completed

      # State Machine events
      event :start do
        transitions to: :processing, from: %i[pending failed completed processing]
      end

      event :finished do
        transitions to: :completed, from: [:processing]
      end

      event :fail do
        transitions to: :failed, from: [:processing]
      end
    end
  end
  private :configure_state_machine
end
