# frozen_string_literal: true

# A cherrypick {Batch} can source one or more controls from a {ControlPlate}
# For the initial destination plate in a batch these controls are distributed
# (pseudo)randomly across available wells. (Two controls can't occupy the same
# wells) Subsequent destination plates within the same batch will offset the
# controls by a fixed amount to ensure destination plates in a batch have
# different control locations.
# This is especially important for negative controls, as it allows plate swaps
# to be identified (the negative control location can be thought of as a
# fingerprint).
#
# Once all well locations have been used, an new set of random locations will
# be generated, and the cycle will begin again.
#
# We need to be particularly careful with the offset value, as otherwise we risk
# reusing wells before the full cycle has been completed. For this reason we
# select prime numbers that are NOT a factor of the number of available wells.
class CherrypickTask::ControlLocator
  # A cherrypick batch may contain multiple destination plates. In this case the control wells
  # should be located at different locations on each destination. The positions on the first
  # plate in a batch are determined randomly, and then the locations are advanced by
  # BETWEEN_PLATE_OFFSET for each subsequent plate. This is done to avoid the risk of
  # subsequent plates having the same negative control location, which would reduce the ability to
  # detect plate swaps.
  # WARNING! These needs to be a prime number (which isn't also a factor of the available well size)
  # to avoid re-using wells prematurely. These offsets are prioritised in order. Technically any
  # number that only shares 1 as a common factor with the available well size would work, but we
  # limit ourself to primes to simplify validation.
  BETWEEN_PLATE_OFFSETS = [53, 59].freeze

  attr_reader :batch_id, :total_wells, :wells_to_leave_free, :num_control_wells, :available_positions

  # @note wells_to_leave_free was originally hardcoded for 96 well plates at 24, in order to avoid
  # control wells being missed in cDNA quant QC. This requirement was removed in
  # https://github.com/sanger/sequencescape/issues/2967 however I've avoided stripping out the behaviour
  # completely in case controls are used in other pipelines.
  #
  # @param batch_id [Integer] The id of the batch, used to generate a starting position
  # @param total_wells [Integer] The total number of wells on the plate
  # @param num_control_wells [Integer] The number of control wells to lay out
  # @param wells_to_leave_free [Enumerable] Array or range indicating the wells to leave free from controls
  def initialize(batch_id:, total_wells:, num_control_wells:, wells_to_leave_free: [])
    @batch_id = batch_id
    @total_wells = total_wells
    @num_control_wells = num_control_wells
    @wells_to_leave_free = wells_to_leave_free.to_a
    @available_positions = (0...total_wells).to_a - @wells_to_leave_free
  end

  #
  # Returns a list with the destination positions for the control wells distributed randomly
  # using batch_id as seed and num_plate to increase position with plates in same batch.
  #
  # @param num_plate [Integer] The plate number within the batch
  #
  # @return [Array<Integer>] The indexes of the control well positions
  #
  def control_positions(num_plate)
    raise StandardError, 'More controls than free wells' if num_control_wells > total_available_positions

    # Check that all elements in wells_to_leave_free fall within the acceptable range
    raise StandardError, 'More wells left free than available' unless wells_to_leave_free.all?(0...total_wells)
    return [] if num_control_wells.zero?

    # If num plate is equal to the available positions, the cycle is going to be repeated.
    # To avoid it, every num_plate=available_positions we start a new cycle with a new seed.
    seed = seed_for(num_plate)
    initial_positions = random_positions_from_available(seed)
    control_positions_for_plate(num_plate, initial_positions)
  end

  private

  # If num plate is equal to the available positions, the cycle is going to be repeated.
  # To avoid it, every num_plate=available_positions we start a new cycle with a new seed.
  def seed_for(num_plate)
    batch_id * ((num_plate / total_available_positions) + 1)
  end

  def total_available_positions
    @available_positions.size
  end

  def control_positions_for_plate(num_plate, initial_positions)
    return initial_positions if num_plate.zero?

    offset = num_plate * per_plate_offset

    initial_positions.map do |pos|
      available_positions[(available_positions.index(pos) + offset) % total_available_positions]
    end
  end

  def random_positions_from_available(seed)
    available_positions.sample(num_control_wells, random: Random.new(seed))
  end

  # Works out which offset to use based on the number of available wells and ensures we use
  # all wells before looping. Will select the first suitable value from BETWEEN_PLATE_OFFSETS
  # excluding any numbers that are a factor of the available wells. In the incredibly unlikely
  # chance nothing matches (essentially the plate size has all offsets as a factor) we fall back
  # to 1, which isn't a prime, but will fulfil the base requirement.
  # This may seem overly cautious, but its the kind of thing that would fail silently if we
  # introduced a new plate size, and wouldn't get noticed for months.
  def per_plate_offset
    @per_plate_offset ||= BETWEEN_PLATE_OFFSETS.detect { |offset| total_available_positions % offset != 0 } || 1
  end
end
