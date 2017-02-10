# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2014,2015 Genome Research Ltd.
require 'aasm'
module Batch::StateMachineBehaviour
  def self.included(base)
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
          transitions to: :started, from: [:pending, :started]
        end

        event :complete do
          transitions to: :completed, from: [:started, :pending, :completed]
        end

        event :release do
          transitions to: :released, from: [:completed, :started, :pending, :released]
        end

        event :discard do
          transitions to: :discarded, from: [:pending]
        end
      end

      scope :failed, -> { where(production_state: 'fail') }

      # We override the behaviour of a couple of events because they require user details.
      alias_method_chain(:start!, :user)
      alias_method_chain(:complete!, :user)
      alias_method_chain(:release!, :user)
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
    lab_events.create!(batch: self, user: user, description: 'Complete').tap do |event|
      event.add_descriptor Descriptor.new(name: 'pipeline_id', value: pipeline.id)
      event.add_descriptor Descriptor.new(name: 'pipeline',    value: pipeline.name)
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

  def create_release_batch_event_for(user)
    lab_events.create!(batch: self, user: user, description: 'Released').tap do |event|
      event.add_descriptor Descriptor.new(name: 'workflow_id', value: workflow.id)
      event.add_descriptor Descriptor.new(name: 'workflow',    value: "Released from #{workflow.name}")
      event.add_descriptor Descriptor.new(name: 'task',        value: workflow.name)
      event.add_descriptor Descriptor.new(name: 'Released',    value: workflow.name)
      event.save!
    end
  end
  private :create_release_batch_event_for
end
