# frozen_string_literal: true

# Purposes of this class represent multiplexed library tubes in the high-throughput
# pipeline. These tubes represent the cleaned-up normalized libraries at the end
# of the process that can pass directly into a {SequencingPipeline}.
# State changes on these tubes will automatically update the requests into the tubes
class IlluminaHtp::MxTubePurpose < Tube::Purpose
  self.state_changer = StateChanger::MxTube

  #
  # Attempts to find the 'stock_plate' for a given tube. However this is a fairly
  # nebulous concept. Often it means the plate that first entered a pipeline,
  # but in other cases it can be the XP plate part way through the process. Further
  # complication comes from tubes which pool across multiple plates, where identifying
  # a single stock plate is meaningless. In other scenarios, you split plates out again
  # and the asset link graph is insufficient.
  #
  # JG: 2021-02-11: In this case we attempt to jump back through the requests. In most
  # limber pipelines this will actually return the plate on which you charge and pass.
  # See https://github.com/sanger/sequencescape/issues/3040 for more information
  #
  # @deprecated Do not use this for new behaviour.
  #
  # @param tube [Tube] The tube for which to find the stock_plate
  #
  # @return [Plate, nil] The stock plate if found
  #
  def stock_plate(tube)
    tube.requests_as_target.where.not(requests: { asset_id: nil }).first&.asset&.plate
  end
  deprecate stock_plate: 'Stock plate is nebulous and can easily lead to unexpected behaviour',
            deprecator: ActiveSupport::Deprecation.new('14.53.0', 'Sequencescape')

  def source_plate(tube)
    super || source_plate_scope(tube).first
  end

  def source_plates(tube)
    super.presence || source_plate_scope(tube)
  end

  def library_source_plates(tube)
    source_plate_scope(tube).map(&:source_plate)
  end

  def source_plate_scope(tube)
    Plate
      .joins(wells: :requests)
      .where(
        requests: {
          target_asset_id: tube.receptacle.id,
          sti_type: [
            Request::Multiplexing,
            Request::AutoMultiplexing,
            Request::LibraryCreation,
            *Request::LibraryCreation.descendants
          ].map(&:name)
        }
      )
      .distinct
  end
end
