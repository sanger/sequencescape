# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

module Cherrypick::VolumeByNanoGrams
  def check_inputs_to_volume_to_cherrypick_by_nano_grams!(minimum_volume, maximum_volume, target_ng, source_well)
    raise 'Source well not found' if source_well.nil?

    raise Cherrypick::VolumeError, "Minimum volume (#{minimum_volume.inspect}) is invalid for cherrypick by nano grams"          if minimum_volume.blank? || minimum_volume <= 0.0
    raise Cherrypick::VolumeError, "Maximum volume (#{maximum_volume.inspect}) is invalid for cherrypick by nano grams"          if maximum_volume.blank? || maximum_volume <= 0.0
    raise Cherrypick::VolumeError, "Maximum volume (#{maximum_volume.inspect}) is less than minimum (#{minimum_volume.inspect})" if maximum_volume < minimum_volume

    raise Cherrypick::AmountError, "Target nano grams (#{target_ng.inspect}) is invalid for cherrypick by nano grams" if target_ng.blank? || target_ng <= 0.0

    source_concentration, source_volume = source_well.well_attribute.concentration, source_well.well_attribute.measured_volume
    raise Cherrypick::VolumeError, "Missing measured volume for well #{source_well.display_name}(#{source_well.id})" if source_volume.blank? || source_volume <= 0.0
    raise Cherrypick::ConcentrationError, "Missing measured concentration for well #{source_well.display_name}(#{source_well.id})" if source_concentration.blank?
    raise Cherrypick::ConcentrationError, "Concentration is negative for well #{source_well.display_name}(#{source_well.id})" if source_concentration < 0.0
  end
  private :check_inputs_to_volume_to_cherrypick_by_nano_grams!

  def volume_to_cherrypick_by_nano_grams(minimum_volume, maximum_volume, target_ng, source_well, robot_minimum_picking_volume = 0.0)
    robot_minimum_picking_volume ||= 0.0
    check_inputs_to_volume_to_cherrypick_by_nano_grams!(minimum_volume, maximum_volume, target_ng, source_well)

    source_concentration = source_well.well_attribute.concentration.to_f
    source_volume        = source_well.well_attribute.estimated_volume # Current volume, fall back to measured if current not set
    desired_volume = source_volume
    unless source_concentration.zero?
      desired_volume = [(target_ng.to_f / source_concentration), robot_minimum_picking_volume].max
    end
    requested_volume     = [source_volume, desired_volume].min
    buffer_volume        = buffer_volume_required(minimum_volume, requested_volume, robot_minimum_picking_volume)
    requested_volume     = maximum_volume if requested_volume > maximum_volume

    well_attribute.current_volume   = minimum_volume
    well_attribute.requested_volume = minimum_volume
    well_attribute.picked_volume    = requested_volume
    well_attribute.buffer_volume    = buffer_volume
    well_attribute.robot_minimum_picking_volume = robot_minimum_picking_volume

    requested_volume
  end

  def buffer_volume_required(minimum_volume, requested_volume, robot_minimum_picking_volume)
    val = [minimum_volume - requested_volume, 0.0].max
    if val > 0.0
      val = [val, robot_minimum_picking_volume].max
    end
    val
  end
  private :buffer_volume_required
end
