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
    well_to_destination.each do |source, destination_and_additional_information|
      destination, *extra_information = Array(destination_and_additional_information)

      # source here is the parent well for this transfer.
      # extra_information[0] contains the source_wells array going into the destination tube, where
      # usually multiple parent plate source wells are pooled into the same tube.
      source_wells = extra_information.first || []
      source_well = source_wells.first
      # We want the active submission chosen to go forward for the source well, if one exists
      submission_id = active_submission_id_for(source_well || source)
      yield(source, destination, submission_id)
      record_transfer(source, destination, *extra_information)
    end
  end

  # Builds a hash mapping each stock well to its destination MX library tube and the array of
  # source plate wells that trace back to that stock well.
  # Overrides the parent implementation to pass the source plate well through to
  # locate_mx_library_tube_for, so the active submission can be resolved from the current
  # plate rather than from the stock well (which may carry a stale submission reference).
  def well_to_destination
    source
      .stock_wells
      .each_with_object({}) do |(stock_well, source_wells), store|
        # Find the corresponding well on the source plate that has the active requests
        # We use the first source well as they should all have the same submission for transfer purposes
        source_well = source_wells.first
        tube = locate_mx_library_tube_for(stock_well, source_wells, source_well)
        next if tube.nil? || should_well_not_be_transferred?(stock_well)

        store[stock_well] = [tube, source_wells]
      end
  end

  # Returns the MX library tube that the given well should be transferred into.
  # Resolves the correct tube by looking up the active submission on the source plate well
  # (passed as source_well). Falls back to using the stock well itself if no source well is
  # provided, preserving backwards-compatible behaviour for callers that do not supply one.
  def locate_mx_library_tube_for(well, _stock_wells, source_well = nil)
    well_to_check = source_well || well
    asset_cache[active_submission_id_for(well_to_check)]
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
