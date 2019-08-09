# frozen_string_literal: true

# Temporary placeholder class until we introduce Flowcell proper
class Lane::Labware < Labware
  include SingleReceptacleLabware
  # Not entirely sure this is correct, as really flowcells are the labware,
  # but we do rely on asset link to Lane. Currently aware of:
  # - Linking in {SpikedBuffer}, although this could be replaced with an actual transfer
  # - Finding lanes for a given plate on eg. the {PlateSummariesController plate summary}
  include AssetRefactor::Labware::Methods

  self.receptacle_class = 'Lane'

  def labwhere_location
    nil
  end

  def human_barcode
    source_request.try(:flowcell_barcode)
  end
end
