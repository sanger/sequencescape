# frozen_string_literal: true
# At the end of the pulldown pipeline the wells of the final plate are transferred, individually,
# into MX library tubes.  Each well is effectively a pool of the stock wells, once they've been
# through the pipeline, so the mapping needs to be based on the original submissions.
class Transfer::FromPlateToTubeBySubmission < Transfer::BetweenPlateAndTubes
  after_create :build_asset_links

  private

  # Iterates over each well-to-tube transfer, yielding the source well, the destination MX library
  # tube, and the active submission_id for the corresponding source plate well.
  # Overrides the default behaviour in Transfer::ControlledDestinations to pass the correct
  # submission_id to TransferRequest, preventing stale submission IDs being used when a well
  # has requests from both a completed and a new active submission.
  def each_transfer
    well_to_destination.each do |source_plate_well, destination_and_additional_information|
      destination, *extra_information = Array(destination_and_additional_information)

      # The hash key is the well on the transfer's source plate.
      # The additional information contains the ancestor stock wells pooled into the destination tube.
      ancestor_stock_wells = extra_information.first || []
      submission_well = ancestor_stock_wells.first || source_plate_well
      # Use the active submission associated with the first ancestor stock well, when available.
      submission_id = active_submission_id_for(submission_well)
      yield(source_plate_well, destination, submission_id)
      record_transfer(source_plate_well, destination, *extra_information)
    end
  end

  # Builds a hash mapping each source-plate well to its destination MX library tube and its
  # ancestor stock wells. The first ancestor stock well is used to resolve the submission and tube.
  def well_to_destination
    # source.stock_wells returns a hash like:
    # {
    #   source_plate_well => [ancestor_stock_well_1, ancestor_stock_well_2]
    # }
    source
      .stock_wells
      .each_with_object({}) do |(source_plate_well, ancestor_stock_wells), store|
        submission_well = ancestor_stock_wells.first || source_plate_well
        tube = locate_mx_library_tube_for(source_plate_well, ancestor_stock_wells, submission_well)
        next if tube.nil? || should_well_not_be_transferred?(source_plate_well)

        store[source_plate_well] = [tube, ancestor_stock_wells]
      end
  end

  # Returns the MX library tube that the given well should be transferred into.
  # Resolves the tube using the active submission associated with the submission well.
  def locate_mx_library_tube_for(_source_plate_well, _ancestor_stock_wells, submission_well)
    asset_cache[active_submission_id_for(submission_well)]
  end

  # Returns the submission_id of the first active (pending or started) request on the well's
  # requests_as_source. Falls back to the well's first submission_id when no active request
  # is found, handling the normal single-submission case and the aggregation case where the
  # outer request is nil.
  def active_submission_id_for(well)
    well
      .requests_as_source
      .find { |r| %w[pending started].include?(r.state) }
      &.submission_id || well.submission_ids.first
  end

  # Memoised hash that maps a submission_id to the multiplexed labware created for that
  # submission. Entries are populated on first access, so each submission is looked up at
  # most once per transfer operation.
  # @return [Hash{Integer => Labware}]
  def asset_cache
    @asset_cache ||=
      Hash.new { |cache, submission_id| cache[submission_id] = Submission.find(submission_id).multiplexed_labware }
  end
end
