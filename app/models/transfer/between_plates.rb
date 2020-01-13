# Picks the specified wells from one plate into the wells of another.  In this case transfers
# is a hash from source to destination well location and destination is the target plate for
# the transfers.
class Transfer::BetweenPlates < Transfer
  extend ::ModelExtensions::Plate::NamedScopeHelpers
  include_plate_named_scope :source
  include_plate_named_scope :destination

  include TransfersBySchema
  include TransfersToKnownDestination

  include Asset::Ownership::ChangesOwner
  set_target_for_owner(:destination)

  # The values in the transfers must be a hash and must be valid well positions on both the
  # source and destination plates.
  validates_each(:transfers) do |record, _attribute, value|
    if not value.is_a?(Hash)
      record.errors.add(:transfers, 'must be a map from source to destination location')
    elsif record.source.present? and not record.source.valid_positions?(value.keys)
      record.errors.add(:transfers, 'are not valid positions for the source plate')
    elsif record.destination.present? and not record.destination.valid_positions?(value.values.flatten)
      record.errors.add(:transfers, "#{value.values.inspect} are not valid positions for the destination plate")
    end
  end

  private

  #--
  # Transfers between plates may encounter empty source wells, in which case we don't bother
  # making that transfer.  In the case of the pulldown pipeline this could happen after the
  # plate has been put on the robot, as the number of columns transfered could be less than
  # an entire plate.  Subsequent plates are therefore only partially complete.
  #++
  def each_transfer
    # Partition the source plate wells into ones that are good and others that are bad.  The
    # bad wells will be eliminated after we've done the transfers for the good ones.
    bad_wells, good_wells = source.wells.located_at_position(transfers.keys).with_pool_id.partition(&method(:should_well_not_be_transferred?))
    source_wells          = good_wells.index_by(&:map_description)
    destination_locations = source_wells.keys.map { |p| transfers[p] }.flatten
    destination_wells     = destination.wells.located_at_position(destination_locations).index_by(&:map_description)

    source_wells.each do |location, source_well|
      Array(transfers[location]).each do |target_well_location|
        yield(source_well, destination_wells[target_well_location], location_submissions[target_well_location])
      end
    end

    # Eliminate any of the transfers that were not made because of the bad source wells
    transfers_we_did_not_make = bad_wells.map(&:map_description)
    transfers.delete_if { |k, _| transfers_we_did_not_make.include?(k) }
  end

  #
  # A hash of destination wells and the submission the are associated
  # Returns an empty hash if not relevant.
  # This is relevant when ISC repool submissions have been made as
  # not only will the new well belong to a different submission to
  # the original, but potentially one source well may be part of
  # multiple re-pool submissions.
  # @return [Hash] Destination wells and associated submission
  #                eg. { 'A1' => 12345, 'B1' -> 67890 }
  def location_submissions
    @location_submissions ||= calculate_location_submissions
  end

  #
  # See: #location_submissions which memoizes this
  #
  # @return [Hash] Destination wells and associated submission
  #                eg. { 'A1' => 12345, 'B1' -> 67890 }
  def calculate_location_submissions
    # We're probably just stamping
    return {} if simple_stamp? || pre_cap_groups.empty?

    destination_sources.each_with_object({}) do |dest_source, store|
      dest_loc, sources = *dest_source

      found_pre_cap_gropus = pre_cap_groups.select { |_uuid, group_details| group_details[:wells].sort == sources.sort }

      if found_pre_cap_gropus.keys.length > 1
        errors.add(:base, "Found #{found_pre_cap_gropus.keys.length} different pools matching the condition for #{sources} to #{dest_loc} with requests in state start or pending. Please cancel the requests not needed.")
        raise ActiveRecord::RecordInvalid, self
      end

      uuid = found_pre_cap_gropus.keys.first
      transfer_details = found_pre_cap_gropus[uuid]

      if transfer_details.nil?
        errors.add(:base, "Could not find appropriate pool for #{sources} to #{dest_loc}. Check you don't have repool submissions on failed wells.")
        raise ActiveRecord::RecordInvalid, self
      end

      pre_cap_groups.delete(uuid)
      store[dest_loc] = transfer_details[:submission_id]
    end
  end

  def pre_cap_groups
    @pre_cap_groups ||= source.pre_cap_groups
  end

  #
  # For most transfers we have a one to one mapping of source and destination
  # in these cases we don't care about setting new submissions. We don't actually
  # check the number of items in the array, as repools of a single well are still
  # valid.
  #
  # @return [<type>] <description>
  #
  def simple_stamp?
    transfers.values.none? { |destination| destination.is_a?(Array) }
  end

  #
  # A hash of destination wells and their sources
  #
  # @return [Hash] Destination wells with an array of source wells
  #                eg. { 'A1' => ['A1', 'B1'] }
  #
  def destination_sources
    @destination_sources ||= begin
      dest_sources = Hash.new { |h, i| h[i] = [] }
      transfers.each do |source, dests|
        dests.each { |dest| dest_sources[dest] << source }
      end
      dest_sources
    end
  end
end
