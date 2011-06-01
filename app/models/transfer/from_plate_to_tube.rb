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
    transfers.each do |location|
      yield(well_from(source, location), destination)
    end
  end
  private :each_transfer
end

