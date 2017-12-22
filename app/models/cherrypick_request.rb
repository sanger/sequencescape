# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2014,2015 Genome Research Ltd.

# This class is due to replace CherrypickForPulldownRequest
class CherrypickRequest < CustomerRequest
  after_create :build_stock_well_links

  # On starting a request the aliquots are copied from the source asset to the target
  # and updated with the project and study information from the request itself.
  def on_started
    # raise StandardError
    TransferRequest::Standard.create(asset: asset, target_asset: target_asset, state: 'passed')
  end

  def reduce_source_volume
    return unless asset.get_current_volume
    subtracted_volume = target_asset.get_picked_volume
    new_volume = asset.get_current_volume - subtracted_volume
    asset.set_current_volume(new_volume)
  end

  private

  def build_stock_well_links
    stock_wells = asset.plate.try(:plate_purpose).try(:stock_plate?) ? [asset] : asset.stock_wells
    target_asset.stock_wells.attach!(stock_wells)
  end
end
