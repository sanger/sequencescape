# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2015,2016 Genome Research Ltd.

# Picks the specified wells of a plate into an individual tube.  In this case transfers is an
# array of well locations to transfer into the tube, and the destination is a tube.
class Transfer::FromPlateToTube < Transfer
  include TransfersBySchema
  include TransfersToKnownDestination

  # The values in the transfers must be an array and must be valid well positions on the plate.
  validates_each(:transfers) do |record, _attribute, value|
    if not value.is_a?(Array)
      record.errors.add(:transfers, 'must be an array of well positions')
    elsif record.source.present? and not record.source.valid_positions?(value)
      record.errors.add(:transfers, 'are not valid positions on the source plate')
    end
  end

  def each_transfer
    # Partition the source plate wells into ones that are good and others that are bad.  The
    # bad wells will be eliminated after we've done the transfers for the good ones.
    bad_wells, good_wells = source.wells.located_at_position(transfers).with_pool_id.partition do |well|
      well.nil? or well.aliquots.empty? or well.failed? or well.cancelled?
    end

    good_wells.each { |well| yield(well, destination) }

    # Eliminate any of the transfers that were not made because of the bad source wells
    self.transfers = transfers - bad_wells.map { |well| well.map.description }
  end
  private :each_transfer

  # Request type is based on the destination tube from the source plate
  def request_type_between(_, destination)
    destination.transfer_request_type_from(source)
  end
  private :request_type_between

  after_create :update_tube_name

  def update_tube_name
    source_barcode = source.source_plate.try(:sanger_human_barcode)
    range = "#{transfers.first}:#{transfers.last}"
    destination.update_attributes!(name: "#{source_barcode} #{range}")
  end
  private :update_tube_name
end
