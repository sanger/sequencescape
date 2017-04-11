# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2014,2015 Genome Research Ltd.

# This class is due to replace CherrypickForPulldownRequest
class CherrypickRequest < TransferRequest
  redefine_aasm column: :state, whiny_persistence: true do
    # The statemachine for transfer requests is more promiscuous than normal requests, as well
    # as being more concise as it has less states.
    state :pending, initial: true
    state :started
    state :failed, enter: :on_failed
    state :passed
    state :cancelled, enter: :on_cancelled
    state :hold

    event :hold do
      transitions to: :hold, from: [:pending]
    end

    # State Machine events
    event :start do
      transitions to: :started, from: [:pending, :hold]
    end

    event :pass do
      transitions to: :passed, from: [:pending, :started, :failed]
    end

    event :fail do
      transitions to: :failed, from: [:pending, :started, :passed]
    end

    event :cancel do
      transitions to: :cancelled, from: [:started, :passed]
    end

    event :cancel_before_started do
      transitions to: :cancelled, from: [:pending, :hold]
    end

    event :submission_cancelled do
      transitions to: :cancelled, from: [:pending, :cancelled]
    end

    event :detach do
      transitions to: :pending, from: [:pending, :cancelled]
    end
  end

  def on_failed
    # Do nothing
  end

  alias_method :on_cancelled, :on_failed

  def perform_transfer_of_contents
    transfer_aliquots # Ensures we set the study/project
  end
  private :perform_transfer_of_contents

  after_create :build_stock_well_links

  def build_stock_well_links
    stock_wells = asset.plate.try(:plate_purpose).try(:stock_plate?) ? [asset] : asset.stock_wells
    target_asset.stock_wells.attach!(stock_wells)
  end
  private :build_stock_well_links

  def reduce_source_volume
    return unless asset.get_current_volume
    subtracted_volume = target_asset.get_picked_volume
    new_volume = asset.get_current_volume - subtracted_volume
    asset.set_current_volume(new_volume)
  end
end
