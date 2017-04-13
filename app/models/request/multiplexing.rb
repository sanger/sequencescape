# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

class Request::Multiplexing < CustomerRequest
  after_create :register_transfer_callback

  # Triggers immediate transfer into the tubes if the source asset already
  # exists. This allows multiplexing requests to be made on plates at the
  # end of library prep, after the plate is qc_complete.
  # If no asset is present then we haven't got to that stage yet and transfer
  # will be triggered as part of the standard workflow.
  def register_transfer_callback
    # We go via order as we need to get a particular instance of submission
    order.submission.register_callback(:once) do
      Transfer::FromPlateToTubeByMultiplex.create!(
        source: asset.plate,
        user: order.user
      )
    end if asset.present?
  end

  redefine_aasm column: :state, whiny_persistence: true do
      state :pending, initial: true
      state :started
      state :passed
      state :failed
      state :cancelled

      event :start  do transitions to: :started,     from: [:pending] end
      event :pass   do transitions to: :passed,      from: [:pending, :started] end
      event :fail   do transitions to: :failed,      from: [:pending, :started] end
      event :cancel do transitions to: :cancelled,   from: [:started, :passed] end
  end
end
