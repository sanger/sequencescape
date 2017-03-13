# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

module Qcable::Statemachine
  module ClassMethods
    # A little more sensitive than the request state machine
    def suggested_transition_between(current, target)
      aasm.state_machine.events.select do |_name, event|
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
      ## namespace: true as destroyed clashes with rails, but we can't easily rename the state
      aasm column: :state, whiny_persistence: true, namespace: true, name: 'qc_state' do
        state :created
        state :pending,        enter: :on_stamp
        state :failed,         enter: :on_failed
        state :passed,         enter: :on_passed
        state :available,      enter: :on_released
        state :destroyed,      enter: :on_destroyed
        state :qc_in_progress, enter: :on_qc
        state :exhausted,      enter: :on_used

        initial_state Proc.new { |qcable| qcable.default_state }

        # State Machine events
        event :do_stamp do
          transitions to: :pending, from: [:created]
        end

        event :destroy_labware do
          transitions to: :destroyed, from: [:pending, :available], allow_automated?: true
        end

        event :qc do
          transitions to: :qc_in_progress, from: [:pending], allow_automated?: true
        end

        event :release do
          transitions to: :available, from: [:pending]
        end

        event :pass do
          transitions to: :passed, from: [:qc_in_progress]
        end

        event :fail do
          transitions to: :failed, from: [:qc_in_progress, :pending]
        end

        event :use do
          transitions to: :exhausted, from: [:available], allow_automated?: true
        end
      end

     # new version of combinable named_scope
     scope :for_state, ->(state) { where(state: state) }

     scope :available,   -> { where(state: :available) }
     scope :unavailable, -> { where(state: [:created, :pending, :failed, :passed, :destroyed, :qc_in_progress, :exhausted]) }
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

  def transition_to(target_state)
    send("#{self.class.suggested_transition_between(state, target_state)}!")
  end
end
