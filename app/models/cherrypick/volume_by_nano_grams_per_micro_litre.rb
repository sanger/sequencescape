# frozen_string_literal: true
# Included in {Well} to provide calculations for cherrypicking
module Cherrypick::VolumeByNanoGramsPerMicroLitre
  #
  # Used in the cherrypicking process to calculate the relative volumes of source
  # and buffer required to reach the target volume and concentration.
  #
  # - Ideally will aim for a target well containing volume_required at concentration_required
  # - This will be made by combining material from the source well (picked_volume) and
  #   buffer (buffer_volume)
  # - Maximum picked_volume is limited by source_volume and volume_required
  # - If source_volume < volume_required then buffer will be added to make up volume_required
  #   even if it reduces the target concentration below concentration_required
  #
  # @param volume_required [Float] The volume to aim for in the target well (self)
  # @param concentration_required [Float] The concentration to aim for in the target well (self)
  # @param source_concentration [Float] The concentration (ng/ul) in the source well
  # @param source_volume [Float] The volume (ul) in the source well (ie. the maximum pick)
  # @param robot_minimum_picking_volume [Float] (ul) the minimum volume the robot can pick
  #
  # @return [Float] The total volume that will be picked from the source well
  #
  # rubocop:todo Metrics/MethodLength, Metrics/AbcSize
  def volume_to_cherrypick_by_nano_grams_per_micro_litre(
    volume_required,
    concentration_required,
    source_concentration,
    source_volume,
    robot_minimum_picking_volume = 0.0
  )
    robot_minimum_picking_volume ||= 0

    check_inputs_to_volume_to_cherrypick_by_nano_grams_per_micro_litre!(
      volume_required,
      concentration_required,
      source_concentration
    )

    # @note Here we appear to set the concentration based on the required concentration, regardless of whether we hit it
    # it or not. Checking if this behaviour is desired RT#719205
    well_attribute.concentration = concentration_required
    well_attribute.requested_volume = volume_required

    # Similarly we set current volume based on required. This is only untrue in rare edge cases though
    # (When you have almost all your required volume from your source, then add more buffer than intended
    #  due to minimum robot picks)
    well_attribute.current_volume = volume_required

    # The minimum picking volume is determined by the robot.
    # Even if there is less liquid in the source than the minimum picking volume,
    # we still give the robot the minimum picking volume as its instruction.
    # minimum_picking_volume = [robot_minimum_picking_volume, source_volume].compact.min
    minimum_picking_volume = robot_minimum_picking_volume

    # The maximum picking volume is limited by the source volume, and the volume
    # required.
    maximum_picking_volume = [volume_required, source_volume].compact.min

    # If we've managed to set the maximum picking volume to lower than the the min, set them to the same.
    # This would happen with very low source volumes that are less than the robot_minimum_picking_volume.
    maximum_picking_volume = minimum_picking_volume if minimum_picking_volume > maximum_picking_volume

    volume_needed =
      if source_concentration.zero?
        volume_required # If we have no material, then transfer everything
      else
        (volume_required * concentration_required) / source_concentration
      end

    # clamp applies maximum and minimum values to volume_needed
    volume_to_pick = volume_needed.clamp(minimum_picking_volume..maximum_picking_volume)

    well_attribute.picked_volume = volume_to_pick
    well_attribute.buffer_volume = buffer_volume_required(volume_required, volume_to_pick, robot_minimum_picking_volume)
    well_attribute.robot_minimum_picking_volume = robot_minimum_picking_volume

    volume_to_pick
  end

  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  private

  # rubocop:todo Metrics/MethodLength
  def check_inputs_to_volume_to_cherrypick_by_nano_grams_per_micro_litre!(
    volume_required,
    concentration_required,
    source_concentration
  )
    if volume_required.to_f <= 0.0
      raise Cherrypick::VolumeError, "Volume required (#{volume_required.inspect}) should be greater than zero"
    end
    if concentration_required.to_f <= 0.0
      raise Cherrypick::ConcentrationError,
            "Concentration required (#{concentration_required.inspect}) should be greater than zero"
    end
    if source_concentration.blank? || source_concentration.to_f < 0.0
      raise Cherrypick::ConcentrationError,
            # rubocop:todo Layout/LineLength
            "Source concentration (#{source_concentration.inspect}) is invalid for cherrypick by nano grams per micro litre"
      # rubocop:enable Layout/LineLength
    end
  end
  # rubocop:enable Metrics/MethodLength
end
