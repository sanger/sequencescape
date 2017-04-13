# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2014,2015,2016 Genome Research Ltd.

# Every request "moving" an asset from somewhere to somewhere else without really transforming it
# (chemically) as, cherrypicking, pooling, spreading on the floor etc
class TransferRequest < SystemRequest
  redefine_aasm column: :state, whiny_persistence: true do
    # The statemachine for transfer requests is more promiscuous than normal requests, as well
    # as being more concise as it has fewer states.
    state :pending, initial: true
    state :started
    state :failed, enter: :on_failed
    state :passed
    state :qc_complete
    state :cancelled, enter: :on_cancelled

    # State Machine events
    event :start do
      transitions to: :started, from: [:pending], after: :on_started
    end

    event :pass do
      # Jumping straight to passed moves through an implied started state.
      transitions to: :passed, from: :pending, after: :on_started
      transitions to: :passed, from: [:started, :failed]
    end

    event :fail do
      transitions to: :failed, from: [:pending, :started, :passed]
    end

    event :cancel do
      transitions to: :cancelled, from: [:started, :passed, :qc_complete]
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

  # Ensure that the source and the target assets are not the same, otherwise bad things will happen!
  validate do |record|
    if record.asset.present? and record.asset == record.target_asset
      record.errors.add(:asset, 'cannot be the same as the target')
      record.errors.add(:target_asset, 'cannot be the same as the source')
    end
  end

  before_create(:add_request_type)
  def add_request_type
    self.request_type ||= RequestType.transfer
  end
  private :add_request_type

  after_create(:perform_transfer_of_contents)

  def perform_transfer_of_contents
    begin
      target_asset.aliquots << asset.aliquots.map(&:dup) unless asset.failed? or asset.cancelled?
    rescue ActiveRecord::RecordNotUnique => exception
      # We'll specifically handle tag clashes here so that we can produce more informative messages
      raise exception unless /aliquot_tags_and_tag2s_are_unique_within_receptacle/ === exception.message
      errors.add(:asset, "contains aliquots which can't be transferred due to tag clash")
      raise Aliquot::TagClash, self
    end
  end
  private :perform_transfer_of_contents

  # Run on start, or if start is bypassed
  def on_started
    nil # Do nothing
  end
  private :on_started

  def on_failed
    target_asset.remove_downstream_aliquots if target_asset
  end
  private :on_failed

  alias_method :on_cancelled, :on_failed

  def remove_unused_assets
    # Don't remove assets for transfer requests as they are made on creation
  end
end
