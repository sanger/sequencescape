# frozen_string_literal: true
# Represents a prepared library or multiplexed library which is
# still undergoing normalization, or is at a higher concentration than is
# required for {SequencingPipeline}. A stock may be stored to return to later
# is more material is required. (Although in practice the Lims doesn't always make)
# this as easy as it should.
# Used by external applications.
class IlluminaHtp::StockTubePurpose < Tube::Purpose
  self.state_changer = StateChanger::StockTube

  def create_with_request_options(_tube)
    raise 'Unimplemented behaviour'
  end

  #
  # Attempts to find the 'stock_plate' for a given tube. However this is a fairly
  # nebulous concept. Often it means the plate that first entered a pipeline,
  # but in other cases it can be the XP plate part way through the process. Further
  # complication comes from tubes which pool across multiple plates, where identifying
  # a single stock plate is meaningless. In other scenarios, you split plates out again
  # and the asset link graph is insufficient.
  #
  # JG: 2021-02-11: Previously this code attempted to walk the request graph, but this
  # is slow, and failed with a no method error if it reached the end of the graph without
  # finding a stock plate. This change *does* change the behaviour of this method for some
  # tubes, most notably those in the PF and GBS pipelines. However an audit determined
  # that we're not really using that code in those contexts. I've decided to unify the behaviour
  # with that in plate, and deprecate it.
  # See https://github.com/sanger/sequencescape/issues/3040 for more information
  #
  # @deprecated Do not use this for new behaviour.
  #
  # @param tube [Tube] The tube for which to find the stock_plate
  #
  # @return [Plate, nil] The stock plate if found
  #
  def stock_plate(tube)
    tube.ancestors.stock_plates.order(id: :desc).first
  end
  deprecate stock_plate: 'Stock plate is nebulous and can easily lead to unexpected behaviour',
            deprecator: Rails.application.deprecators[:sequencescape]

  def stock_wells(tube)
    tube.requests_as_target.map { |request| request.asset.stock_wells }.flatten
  end
end
