# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

class Request::Multiplexing < CustomerRequest
  # If we re request we need to make sure we look in the new
  # source wells for our repool
  after_create :flag_asset_as_stock_well, if: :asset
  def flag_asset_as_stock_well
    asset.stock_wells << asset
  end

  redefine_aasm column: :state, whiny_persistence: true do
    state :pending, initial: true
    state :started
    state :passed
    state :failed
    state :cancelled

    event :submission_cancelled do
      transitions to: :cancelled, from: [:pending, :cancelled]
    end
    event :start  do transitions to: :started,     from: [:pending] end
    event :pass   do transitions to: :passed,      from: [:pending, :started] end
    event :fail   do transitions to: :failed,      from: [:pending, :started] end
    event :cancel do transitions to: :cancelled,   from: [:started, :passed] end

    # If the library creation is failed, we're not going to be pooling.
    event :fail_from_upstream do
      transitions to: :cancelled, from: [:pending]
      transitions to: :failed,    from: [:started]
      transitions to: :failed,    from: [:passed]
    end
  end
end
