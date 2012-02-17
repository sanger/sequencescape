# Picks the specified wells from one plate into the wells of another.  In this case transfers
# is a hash from source to destination well location and destination is the target plate for
# the transfers.
class Transfer::BetweenPlates < Transfer
  extend ::ModelExtensions::Plate::NamedScopeHelpers
  include_plate_named_scope :source
  include_plate_named_scope :destination

  include TransfersBySchema
  include TransfersToKnownDestination

  # The values in the transfers must be a hash and must be valid well positions on both the
  # source and destination plates.
  validates_each(:transfers) do |record, attribute, value|
    if not value.is_a?(Hash)
      record.errors.add(:transfers, 'must be a map from source to destination location')
    elsif record.source.present? and not record.source.valid_positions?(value.keys) 
      record.errors.add(:transfers, 'are not valid positions for the source plate')
    elsif record.destination.present? and not record.destination.valid_positions?(value.values)
      record.errors.add(:transfers, 'are not valid positions for the destination plate')
    end
  end

  #--
  # Transfers between plates may encounter empty source wells, in which case we don't bother
  # making that transfer.  In the case of the pulldown pipeline this could happen after the
  # plate has been put on the robot, as the number of columns transfered could be less than
  # an entire plate.  Subsequent plates are therefore only partially complete.
  #++
  def each_transfer(&block)
    # Partition the source plate wells into ones that are good and others that are bad.  The
    # bad wells will be eliminated after we've done the transfers for the good ones.
    bad_wells, good_wells = source.wells.located_at_position(transfers.keys).with_pool_id.partition(&method(:should_well_not_be_transferred?))
    source_wells          = Hash[good_wells.map { |well| [well.map.description, well] }]
    destination_locations = source_wells.keys.map { |p| transfers[p] }
    destination_wells     = Hash[destination.wells.located_at_position(destination_locations).map { |well| [well.map.description, well] }]

    source_wells.each do |location, source_well|
      yield(source_well, destination_wells[transfers[location]])
    end

    # Eliminate any of the transfers that were not made because of the bad source wells
    transfers_we_did_not_make = bad_wells.map { |well| well.map.description }
    transfers.delete_if { |k,_| transfers_we_did_not_make.include?(k) }
  end
  private :each_transfer
end

