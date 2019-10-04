# @deprecated Part of the old Illumina-B ISC pipeline
#
# First ISC plate downstream of the PCR-XP plate.
#
# - ISCH lib pool
#
# @todo #2396 Remove this class. This will require:
#       - Update any purposes using this class to use PlatePurpose instead
#       - Update:
#           app/models/pulldown/plate_purposes.rb
#         By either replacing with PlatePurpose, or removing the factories entirely
class Pulldown::InitialDownstreamPlatePurpose < IlluminaHtp::InitialDownstreamPlatePurpose
  # Initial plates in the pulldown pipelines change the state of the pulldown requests they are being
  # created for to exactly the same state.

  def stock_wells(plate, contents)
    return plate.parents.map(&:wells).flatten if contents.blank?

    Well.joins(:requests).where(requests: { target_asset_id: plate.wells.located_at(contents).pluck(:id) })
  end

  def supports_multiple_submissions?; true; end
end
