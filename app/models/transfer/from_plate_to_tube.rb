# frozen_string_literal: true
# Picks the specified wells of a plate into an individual tube.  In this case transfers is an
# array of well locations to transfer into the tube, and the destination is a tube.
class Transfer::FromPlateToTube < Transfer
  include TransfersBySchema
  include TransfersToKnownDestination

  before_validation :default_to_all_wells

  # The values in the transfers must be an array and must be valid well positions on the plate.
  validates_each(:transfers) do |record, _attribute, value|
    if value.is_a?(Array)
      record.validate_transfers(value, record.source, 'source')
    else
      record.errors.add(:transfers, 'must be an array of well positions')
    end
  end

  after_create :update_tube_name

  private

  def default_to_all_wells
    self.transfers ||= source.wells.includes(:map).map(&:map_description)
  end

  def update_tube_name
    source_barcode = source.source_plate.try(:human_barcode)
    range = "#{transfers.first}:#{transfers.last}"
    destination.update!(name: "#{source_barcode} #{range}")
  end

  def each_transfer # rubocop:todo Metrics/AbcSize
    # Partition the source plate wells into ones that are good and others that are bad.  The
    # bad wells will be eliminated after we've done the transfers for the good ones.
    source_wells = source.wells.includes(:aliquots, :transfer_requests_as_target)
    bad_wells, good_wells =
      source_wells
        .located_at_position(transfers)
        .with_pool_id
        .partition { |well| well.nil? or well.aliquots.empty? or well.failed? or well.cancelled? }

    good_wells.each { |well| yield(well, destination) }

    # Eliminate any of the transfers that were not made because of the bad source wells
    self.transfers = transfers - bad_wells.map { |well| well.map.description }
  end
end
