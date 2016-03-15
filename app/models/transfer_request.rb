#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2013,2014,2015 Genome Research Ltd.
# Every request "moving" an asset from somewhere to somewhere else without really transforming it
# (chemically) as, cherrypicking, pooling, spreading on the floor etc
class TransferRequest < SystemRequest

  module InitialTransfer
    def perform_transfer_of_contents
      target_asset.aliquots << asset.aliquots.map do |a|
        aliquot = a.dup
        aliquot.study_id = outer_request.initial_study_id
        aliquot.project_id = outer_request.initial_project_id
        aliquot
      end unless asset.failed? or asset.cancelled?
    end
    private :perform_transfer_of_contents

    def outer_request
      asset.requests.detect{|r| r.library_creation? && r.submission_id == self.submission_id}
    end
  end

  redefine_aasm :column => :state do
    # The statemachine for transfer requests is more promiscuous than normal requests, as well
    # as being more concise as it has fewer states.
    state :pending, :initial => true
    state :started
    state :failed,	    :enter => :on_failed
    state :passed
    state :qc_complete
    state :cancelled,  :enter => :on_cancelled

    # State Machine events
    event :start do
      transitions :to => :started, :from => [:pending]
    end

    event :pass do
      transitions :to => :passed, :from => [:pending, :started, :failed]
    end

    event :fail do
      transitions :to => :failed, :from => [:pending, :started, :passed]
    end

    event :cancel do
      transitions :to => :cancelled, :from => [:started, :passed, :qc_complete]
    end

    event :cancel_before_started do
      transitions :to => :cancelled, :from => [:pending]
    end

    event :detach do
      transitions :to => :pending, :from => [:pending]
    end

    # Not all transfer quests will make this transition, but this way we push the
    # decision back up to the pipeline
    event :qc     do
      transitions :to => :qc_complete, :from => [:passed]
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
      errors.add(:asset,"contains aliquots which can't be transferred due to tag clash")
      raise Aliquot::TagClash, self
    end
  end
  private :perform_transfer_of_contents

  def on_failed
    self.target_asset.remove_downstream_aliquots
  end
  private :on_failed

  alias_method :on_cancelled, :on_failed

  def remove_unused_assets
    # Don't remove assets for transfer requests as they are made on creation
  end

end
