# Picks the specified wells from one plate into the wells of another.  In this case transfers
# is a hash from source to destination well location and destination is the target plate for
# the transfers.
class Transfer::BetweenPlates < Transfer
  include TransfersBySchema
  include TransfersToKnownDestination

  # The values in the transfers must be a hash and must be valid well positions on both the
  # source and destination plates.
  validates_each(:transfers) do |record, attribute, value|
    if not value.is_a?(Hash)
      record.errors.add(:transfers, 'must be a map from source to destination location')
    elsif not record.source.valid_positions?(value.keys) or not record.destination.valid_positions?(value.values)
      record.errors.add(:transfers, 'are not valid positions for the source & destination plates')
    end
  end

  def each_transfer(&block)
    transfers.each do |source_location, destination_location|
      yield(well_from(source, source_location), well_from(destination, destination_location))
    end
  end
  private :each_transfer
end

