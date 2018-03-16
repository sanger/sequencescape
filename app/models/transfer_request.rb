# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2014,2015,2016 Genome Research Ltd.

# Every request "moving" an asset from somewhere to somewhere else without really transforming it
# (chemically) as, cherrypicking, pooling, spreading on the floor etc
class TransferRequest < ApplicationRecord
  include Uuid::Uuidable
  include AASM
  extend Request::Statemachine::ClassMethods

  # States which are still considered to be processable (ie. not failed or cancelled)
  ACTIVE_STATES = %w[pending started passed qc_complete].freeze

  has_many :transfer_request_collection_transfer_requests, dependent: :destroy
  has_many :transfer_request_collections, through: :transfer_request_collection_transfer_requests, inverse_of: :transfer_requests

  # The assets on a request can be treated as a particular class when being used by certain pieces of code.  For instance,
  # QC might be performed on a source asset that is a well, in which case we'd like to load it as such.
  belongs_to :target_asset, class_name: 'Receptacle', inverse_of: :transfer_requests_as_source, required: true
  belongs_to :asset, class_name: 'Receptacle', inverse_of: :transfer_requests_as_source, required: true

  has_many :associated_requests, through: :asset, source: :requests_as_source

  belongs_to :order
  belongs_to :submission

  scope :for_request, ->(request) { where(asset_id: request.asset_id) }
  scope :include_submission, -> { includes(submission: :uuid_object) }
  # Ensure that the source and the target assets are not the same, otherwise bad things will happen!
  validate :source_and_target_assets_are_different

  after_create(:perform_transfer_of_contents)

  # state machine
  aasm column: :state, whiny_persistence: true do
    # The statemachine for transfer requests is more promiscuous than normal requests, as well
    # as being more concise as it has fewer states.
    state :pending, initial: true
    state :started
    state :processed_1
    state :processed_2
    state :failed, enter: :on_failed
    state :passed
    state :qc_complete
    state :cancelled, enter: :on_cancelled

    # State Machine events
    event :start do
      transitions to: :started, from: [:pending], after: :on_started
    end

    event :process_1 do
      transitions to: :processed_1, from: [:pending]
    end

    event :process_2 do
      transitions to: :processed_2, from: [:processed_1]
    end

    event :pass do
      # Jumping straight to passed moves through an implied started state.
      transitions to: :passed, from: :pending, after: :on_started
      transitions to: :passed, from: [:started, :failed, :processed_2]
    end

    event :fail do
      transitions to: :failed, from: [:pending, :started, :processed_1, :processed_2, :passed]
    end

    event :cancel do
      transitions to: :cancelled, from: [:started, :processed_1, :processed_2, :passed, :qc_complete]
    end

    event :cancel_before_started do
      transitions to: :cancelled, from: [:pending]
    end

    event :detach do
      transitions to: :pending, from: [:pending]
    end

    # Not all transfer quests will make this transition, but this way we push the
    # decision back up to the pipeline
    event :qc     do
      transitions to: :qc_complete, from: [:passed]
    end
  end

  # validation method
  def source_and_target_assets_are_different
    return true unless asset_id.present? && asset_id == target_asset_id
    errors.add(:asset, 'cannot be the same as the target')
    errors.add(:target_asset, 'cannot be the same as the source')
    false
  end

  def transition_to(target_state)
    aasm.fire!(suggested_transition_to(target_state))
  end

  def outer_request
    asset.outer_request(submission_id)
  end

  # A sibling request is a customer request out of the same asset and in the same submission
  def sibling_requests
    if associated_requests.loaded?
      associated_requests.select { |r| r.submission_id == submission_id }
    else
      associated_requests.where(submission: submission_id)
    end
  end

  private

  # Determines the most likely event that should be fired when transitioning between the two states.  If there is
  # only one option then that is what is returned, otherwise an exception is raised.
  def suggested_transition_to(target)
    valid_events = aasm.events(permitted: true).select { |e| e.transitions_to_state?(target.to_sym) }
    raise StandardError, "No obvious transition from #{state.inspect} to #{target.inspect}" unless valid_events.size == 1
    valid_events.first.name
  end

  # after_create callback method
  def perform_transfer_of_contents
    return if asset.failed? || asset.cancelled?
    target_asset.aliquots << asset.aliquots.map do |a|
      a.dup(aliquot_attributes)
    end
  rescue ActiveRecord::RecordNotUnique => exception
    # We'll specifically handle tag clashes here so that we can produce more informative messages
    raise exception unless /aliquot_tags_and_tag2s_are_unique_within_receptacle/.match?(exception.message)
    errors.add(:asset, "contains aliquots which can't be transferred due to tag clash")
    raise Aliquot::TagClash, self
  end

  def aliquot_attributes
    sibling_requests.first&.aliquot_attributes || {}
  end

  # Run on start, or if start is bypassed
  def on_started
    sibling_requests.each do |sr|
      sr.start! if sr.may_start?
    end
  end

  def on_failed
    target_asset&.remove_downstream_aliquots
  end
  alias on_cancelled on_failed
end
