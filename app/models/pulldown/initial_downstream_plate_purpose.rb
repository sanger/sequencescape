class Pulldown::InitialDownstreamPlatePurpose < IlluminaHtp::InitialDownstreamPlatePurpose
  # Initial plates in the pulldown pipelines change the state of the pulldown requests they are being
  # created for to exactly the same state.

  def stock_wells(plate, contents)
    return plate.parents.map { |parent| parent.wells }.flatten unless contents.present?
    Well.joins(:requests).where(requests: { target_asset_id: plate.wells.located_at(contents).pluck(:id) })
  end

  def supports_multiple_submissions?; true; end
end
