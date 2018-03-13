# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2014,2015 Genome Research Ltd.

# This class is due to replace CherrypickForPulldownRequest
class CherrypickRequest < CustomerRequest
  after_create :build_stock_well_links, :transfer_aliquots

  def on_started
    # Aliquots are transferred on creation by transfer requests.
    # This isn't ideal, but makes the transition easier without
    # slowing actual picks down.
  end

  def on_passed
    target_asset.transfer_requests_as_target.where(submission_id: submission_id).find_each(&:pass!)
  end

  def reduce_source_volume
    return unless asset.get_current_volume
    subtracted_volume = target_asset.get_picked_volume
    new_volume = asset.get_current_volume - subtracted_volume
    asset.set_current_volume(new_volume)
  end

  def remove_unused_assets
    # Don't remove assets for transfer requests as they are made on creation
  end

  private

  # The transfer requests handle the actual transfer
  def transfer_aliquots
    TransferRequest.create(asset: asset, target_asset: target_asset, submission_id: submission_id)
  end

  def build_stock_well_links
    stock_wells = asset.plate.try(:plate_purpose).try(:stock_plate?) ? [asset] : asset.stock_wells
    target_asset.stock_wells.attach!(stock_wells)
  end
end
