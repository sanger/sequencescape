# frozen_string_literal: true
module Cherrypick::VolumeByNanoGrams
  # rubocop:todo Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity
  def check_inputs_to_volume_to_cherrypick_by_nano_grams!(minimum_volume, maximum_volume, target_ng, source_well)
    raise 'Source well not found' if source_well.nil?

    if minimum_volume.blank? || minimum_volume <= 0.0
      raise Cherrypick::VolumeError,
            "Minimum volume (#{minimum_volume.inspect}) is invalid for cherrypick by nano grams"
    end
    if maximum_volume.blank? || maximum_volume <= 0.0
      raise Cherrypick::VolumeError,
            "Maximum volume (#{maximum_volume.inspect}) is invalid for cherrypick by nano grams"
    end
    if maximum_volume < minimum_volume
      raise Cherrypick::VolumeError,
            "Maximum volume (#{maximum_volume.inspect}) is less than minimum (#{minimum_volume.inspect})"
    end

    if target_ng.blank? || target_ng <= 0.0
      raise Cherrypick::AmountError, "Target nano grams (#{target_ng.inspect}) is invalid for cherrypick by nano grams"
    end

    source_concentration, source_volume =
      source_well.well_attribute.concentration,
      source_well.well_attribute.measured_volume
    if source_volume.blank? || source_volume <= 0.0
      raise Cherrypick::VolumeError, "Missing measured volume for well #{source_well.display_name}(#{source_well.id})"
    end

    if source_concentration.blank?
      raise Cherrypick::ConcentrationError,
            "Missing measured concentration for well #{source_well.display_name}(#{source_well.id})"
    end
    if source_concentration < 0.0
      raise Cherrypick::ConcentrationError,
            "Concentration is negative for well #{source_well.display_name}(#{source_well.id})"
    end
  end

  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  private :check_inputs_to_volume_to_cherrypick_by_nano_grams!

  # rubocop:todo Metrics/MethodLength, Metrics/AbcSize
  def volume_to_cherrypick_by_nano_grams(
    minimum_volume,
    maximum_volume,
    target_ng,
    source_well,
    robot_minimum_picking_volume = 0.0
  )
    robot_minimum_picking_volume ||= 0.0
    check_inputs_to_volume_to_cherrypick_by_nano_grams!(minimum_volume, maximum_volume, target_ng, source_well)

    source_concentration = source_well.well_attribute.concentration.to_f

    # Current volume, fall back to measured if current not set
    source_volume = source_well.well_attribute.estimated_volume

    desired_volume = source_volume
    unless source_concentration.zero?
      desired_volume = [(target_ng.to_f / source_concentration), robot_minimum_picking_volume].max
    end
    requested_volume = [source_volume, desired_volume].min
    buffer_volume = calculate_buffer_volume(minimum_volume, requested_volume, robot_minimum_picking_volume)
    requested_volume = maximum_volume if requested_volume > maximum_volume

    well_attribute.current_volume = minimum_volume
    well_attribute.requested_volume = minimum_volume
    well_attribute.picked_volume = requested_volume
    well_attribute.buffer_volume = buffer_volume
    well_attribute.robot_minimum_picking_volume = robot_minimum_picking_volume

    requested_volume
  end

  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  private

  def calculate_buffer_volume(final_volume_desired, volume_so_far, robot_minimum_picking_volume)
    buffer_to_add = final_volume_desired - volume_so_far
    return 0 if buffer_to_add <= 0

    # If we're adding buffer, it needs to be at least the robot_minimum_picking_volume
    buffer_to_add.clamp(robot_minimum_picking_volume..)
  end
end
