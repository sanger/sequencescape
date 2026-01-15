# frozen_string_literal: true
require 'aasm'
module Batch::StateMachineBehaviour
  def self.included(base) # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    base.class_eval do
      include AASM

      aasm column: :state, whiny_persistence: true do
        state :pending, initial: true
        state :started, enter: :start_requests
        state :completed
        state :released
        state :discarded

        # State Machine events
        event :start do
          transitions to: :started, from: [:pending]
        end

        event :complete do
          transitions to: :completed, from: %i[started pending completed]
        end

        event :release do
          transitions to: :released, from: %i[completed started pending released]
        end

        event :discard do
          transitions to: :discarded, from: [:pending]
        end
      end

      scope :failed, -> { where(production_state: 'fail') }

      # We override the behaviour of a couple of events because they require user details.
      alias_method(:start_without_user!, :start!)
      alias_method(:start!, :start_with_user!)
      alias_method(:complete_without_user!, :complete!)
      alias_method(:complete!, :complete_with_user!)
      alias_method(:release_without_user!, :release!)
      alias_method(:release!, :release_with_user!)
    end
  end

  def finished?
    completed? or released?
  end

  def editable?
    pending? or started?
  end

  def start_with_user!(user)
    pipeline.on_start_batch(self, user)
    start_without_user!
  end

  def complete_with_user!(user)
    complete_without_user! unless released?
    create_complete_batch_event_for(user)
    pipeline.post_finish_batch(self, user)
  end

  def create_complete_batch_event_for(user)
    lab_events
      .create!(batch: self, user: user, description: 'Complete')
      .tap do |event|
        event.add_descriptor Descriptor.new(name: 'pipeline_id', value: pipeline.id)
        event.add_descriptor Descriptor.new(name: 'pipeline', value: pipeline.name)
        event.save!
      end
  end
  private :create_complete_batch_event_for

  def release_with_user!(user)
    requests.each { |request| pipeline.completed_request_as_part_of_release_batch(request) }
    release_without_user!
    create_release_batch_event_for(user)
    pipeline.post_release_batch(self, user)
  end

  def create_release_batch_event_for(user) # rubocop:todo Metrics/AbcSize
    lab_events
      .create!(batch: self, user: user, description: 'Released')
      .tap do |event|
        event.add_descriptor Descriptor.new(name: 'workflow_id', value: workflow.id)
        event.add_descriptor Descriptor.new(name: 'workflow', value: "Released from #{workflow.name}")
        event.add_descriptor Descriptor.new(name: 'task', value: workflow.name)
        event.add_descriptor Descriptor.new(name: 'Released', value: workflow.name)
        event.save!
      end
  end
  private :create_release_batch_event_for
end
