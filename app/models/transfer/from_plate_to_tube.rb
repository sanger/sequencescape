# Picks the specified wells of a plate into an individual tube.  In this case transfers is an
# array of well locations to transfer into the tube, and the destination is a tube.
class Transfer::FromPlateToTube < Transfer
  include TransfersBySchema
  include TransfersToKnownDestination

  # The values in the transfers must be an array and must be valid well positions on the plate.
  validates_each(:transfers) do |record, attribute, value|
    if not value.is_a?(Array)
      record.errors.add(:transfers, 'must be an array of well positions')
    elsif record.source.present? and not record.source.valid_positions?(value)
      record.errors.add(:transfers, 'are not valid positions on the source plate')
    end
  end

  def each_transfer(&block)
    # Partition the source plate wells into ones that are good and others that are bad.  The
    # bad wells will be eliminated after we've done the transfers for the good ones.
    bad_wells, good_wells = source.wells.located_at_position(transfers).with_pool_id.partition do |well|
      well.nil? or well.aliquots.empty? or well.failed? or well.cancelled?
    end

    good_wells.each { |well| yield(well, destination) }

    # Eliminate any of the transfers that were not made because of the bad source wells
    self.transfers = self.transfers - bad_wells.map { |well| well.map.description }
  end
  private :each_transfer

  # Request type is based on the destination tube from the source plate
  def request_type_between(_, destination)
    destination.transfer_request_type_from(source)
  end
  private :request_type_between
end

