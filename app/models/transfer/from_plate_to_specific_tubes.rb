# frozen_string_literal: true
class Transfer::FromPlateToSpecificTubes < Transfer::BetweenPlateAndTubes # rubocop:todo Style/Documentation
  # NOTE: This class appears to have been unused since July 2014.
  # We still have persistent models in the database, so need to make
  # sure records are updated when we strip this out. However, as
  # far as I can tell, we should be able to convert existing records to
  # Transfer::BetweenPlateAndTubes with no side effects, as all the behaviour
  # contained within here only affects the after_create callbacks.
  # Additionally: Remove ant transfer template using this class.

  attr_reader :targets

  def targets=(uuids_for_tubes)
    @targets = Uuid.lookup_many_uuids(uuids_for_tubes).map(&:resource)
  end

  private

  def locate_mx_library_tube_for(well, stock_wells)
    return nil if stock_wells.empty?

    @tubes_to_pick ||= targets.dup
    @pools_to_tubes ||= Hash.new { |h, k| h[k] = @tubes_to_pick.shift or raise 'Not enough tubes to pick for pool' }
    @pools_to_tubes[well.pool_id]
  end
end
