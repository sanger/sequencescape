# frozen_string_literal: true
# Included in {Well} to provide calculations for cherrypicking
module Cherrypick::VolumeByNanoGramsPerMicroLitre
  #
  # Used in the cherrypicking process to calculate the relative volumes of source
  # and buffer required to reach the target volume and concentration.
  #
  # - Ideally will aim for a target well containing volume `final_volume_desired`
  #   at concentration `final_conc_desired`
  # - This will be made by combining material from the source well (well_attribute.picked_volume)
  #   and buffer (well_attribute.buffer_volume)
  # - Maximum picked_volume is limited by the amount available (source_volume) and the amount you want
  #   in the target well (final_volume_desired)
  # - If source_volume < final_volume_desired then buffer will be added to make up final_volume_desired
  #   even if it reduces the target concentration below final_conc_desired
  #
  # @param final_volume_desired [Float] The volume to aim for in the target well (self)
  # @param final_conc_desired [Float] The concentration to aim for in the target well (self)
  # @param source_concentration [Float] The concentration (ng/ul) in the source well
  # @param source_volume [Float] The volume (ul) in the source well (ie. the maximum pick)
  # @param robot_minimum_pick_vol [Float] (ul) the minimum volume the robot can pick (the robot
  #        software will reject requests to pick less than this)
  #
  # @return [Float] The volume that we will instruct to robot to pick from the source well
  #
  # rubocop:todo Metrics/MethodLength, Metrics/AbcSize
  def volume_to_cherrypick_by_nano_grams_per_micro_litre(
    final_volume_desired,
    final_conc_desired,
    source_concentration,
    source_volume,
    robot_minimum_pick_vol = 0.0
  )
    robot_minimum_pick_vol ||= 0

    check_inputs_to_volume_to_cherrypick_by_nano_grams_per_micro_litre!(
      final_volume_desired,
      final_conc_desired,
      source_concentration
    )

    # @note Here we appear to set the concentration based on the required concentration, regardless of whether we hit it
    # it or not. Checking if this behaviour is desired RT#719205
    well_attribute.concentration = final_conc_desired
    well_attribute.requested_volume = final_volume_desired

    # Similarly we set current volume based on required. This is only untrue in rare edge cases though
    # (When you have almost all your required volume from your source, then add more buffer than intended
    #  due to minimum robot picks)
    well_attribute.current_volume = final_volume_desired

    # The maximum picking volume is limited by the available source volume, and the final volume desired
    # in the source well.
    # It also cannot be less than the minimum picking volume required by the robot.
    max_pick_volume = [final_volume_desired, source_volume].compact.min
    max_pick_volume = [max_pick_volume, robot_minimum_pick_vol].max

    # calculate the volume of source that contains the amount of material we want in our target well
    # this will then be made up to the desired volume with buffer
    source_volume_needed =
      if source_concentration.zero?
        final_volume_desired # If we have no material, then transfer everything
      else
        (final_volume_desired * final_conc_desired) / source_concentration
      end

    # clamp applies maximum and minimum values to source_volume_needed
    source_volume_to_tell_robot_to_pick = source_volume_needed.clamp(robot_minimum_pick_vol..max_pick_volume)

    # If the available source volume is actually less than the robot minimum picking volume,
    # we note two things - the amount we tell the robot to pick (robot_minimum_pick_vol),
    # and the amount it will actually pick (source_volume)
    # We use the latter for the buffer calculation, to make sure we make the desired final volume.
    # See comments on RT https://rt.sanger.ac.uk/Ticket/Display.html?id=735176
    source_volume_it_will_actually_pick =
      source_volume < robot_minimum_pick_vol ? source_volume : source_volume_to_tell_robot_to_pick

    well_attribute.picked_volume = source_volume_to_tell_robot_to_pick
    well_attribute.buffer_volume = calculate_buffer_volume(final_volume_desired, source_volume_it_will_actually_pick)

    well_attribute.robot_minimum_picking_volume = robot_minimum_pick_vol
    well_attribute.current_volume = robot_minimum_pick_vol if well_attribute.current_volume < robot_minimum_pick_vol

    source_volume_to_tell_robot_to_pick
  end

  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  private

  # rubocop:todo Metrics/MethodLength
  def check_inputs_to_volume_to_cherrypick_by_nano_grams_per_micro_litre!(
    final_volume_desired,
    final_conc_desired,
    source_concentration
  )
    if final_volume_desired.to_f <= 0.0
      raise Cherrypick::VolumeError, "Volume required (#{final_volume_desired.inspect}) should be greater than zero"
    end
    if final_conc_desired.to_f <= 0.0
      raise Cherrypick::ConcentrationError,
            "Concentration required (#{final_conc_desired.inspect}) should be greater than zero"
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
