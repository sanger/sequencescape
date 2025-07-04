# frozen_string_literal: true

# Temporary placeholder class until we introduce Flowcell proper
class Lane::Labware < Labware
  include SingleReceptacleLabware

  # Not entirely sure this is correct, as really flowcells are the labware,
  # but we do rely on asset link to Lane. Currently aware of:
  # - Linking in {SpikedBuffer}, although this could be replaced with an actual transfer
  # - Finding lanes for a given plate on eg. the {PlateSummariesController plate summary}
  #   @note This doesn't use the lanes directly, but rather uses them to find the Sequencing batches.
  #         While descendant_lanes currently looks up Lane::Labware switching to flowcells instead
  #         would still find exactly the same batch ids.
  self.receptacle_class = 'Lane'

  def labwhere_location
    nil
  end

  def human_barcode
    source_request.try(:flowcell_barcode)
  end

  # Respond to 'machine_barcode' to avoid errors in case the lane labware is
  # accessed in the batch tube label printing. The chip barcode associated with
  # the lane is already returned by the 'human_barcode' method.
  # @return [nil]
  def machine_barcode
    nil
  end

  def generate_barcode
    # NOOP
  end
end
