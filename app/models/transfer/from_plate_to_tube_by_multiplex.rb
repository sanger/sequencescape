# frozen_string_literal: true
# In contrast to pooling by submission, this method looks at submissions off the current
# plate. This allows users to use QC feedback to decide how to multiplex their plate.
class Transfer::FromPlateToTubeByMultiplex < Transfer::BetweenPlateAndTubes
  # Not used since 2018-09-17 08:16:28

  after_create :build_asset_links

  private

  def locate_mx_library_tube_for(well)
    well
      .requests_as_source
      .where_is_a(Request::Multiplexing)
      .detect { |r| r.target_asset.aliquots.empty? }
      .try(:target_labware)
  end

  def well_to_destination
    source
      .wells
      .each_with_object({}) do |well, store|
        tube = locate_mx_library_tube_for(well)
        next if tube.nil? || should_well_not_be_transferred?(well)

        Rails.logger.info("app/models/transfer/from_plate_to_tube_by_multiplex.rb: well_to_destination - calling requests_as_target")
        store[well] = [tube, tube.requests_as_target.map(&:asset)]
      end
  end

  # Before creating an instance of this class the appropriate transfers need to be made from a source
  # asset to the destination one.
  # before_create :create_transfer_requests
  def create_transfer_requests
    Rails.logger.info("app/models/transfer/from_plate_to_tube_by_multiplex.rb: create_transfer_requests - calling requests_as_target")
    each_transfer do |source, destination|
      TransferRequest.create!(
        asset: source,
        target_asset: destination,
        submission_id: destination.requests_as_target.first.submission_id
      )
    end
  end

  def build_asset_links
    destinations.each { |destination| AssetLink.create_edge(source, destination) }
  end
end
