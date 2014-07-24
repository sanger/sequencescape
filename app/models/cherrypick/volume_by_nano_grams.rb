module Cherrypick::VolumeByNanoGrams
  def check_inputs_to_volume_to_cherrypick_by_nano_grams!(minimum_volume, maximum_volume, target_ng, source_well)
    raise "Source well not found" if source_well.nil?

    raise Cherrypick::VolumeError, "Minimum volume (#{minimum_volume.inspect}) is invalid for cherrypick by nano grams"          if minimum_volume.blank? || minimum_volume <= 0.0
    raise Cherrypick::VolumeError, "Maximum volume (#{maximum_volume.inspect}) is invalid for cherrypick by nano grams"          if maximum_volume.blank? || maximum_volume <= 0.0
    raise Cherrypick::VolumeError, "Maximum volume (#{maximum_volume.inspect}) is less than minimum (#{minimum_volume.inspect})" if maximum_volume < minimum_volume

    raise Cherrypick::AmountError, "Target nano grams (#{target_ng.inspect}) is invalid for cherrypick by nano grams" if target_ng.blank? || target_ng <= 0.0

    source_concentration, source_volume = source_well.well_attribute.concentration, source_well.well_attribute.measured_volume
    raise Cherrypick::VolumeError, "Missing measured volume for well #{source_well.display_name}(#{source_well.id})"        if source_volume.blank? || source_volume <= 0.0
    raise Cherrypick::ConcentrationError, "Missing measured concentration for well #{source_well.display_name}(#{source_well.id})" if source_concentration.blank? || source_concentration <= 0.0
  end
  private :check_inputs_to_volume_to_cherrypick_by_nano_grams!

  def volume_to_cherrypick_by_nano_grams(minimum_volume, maximum_volume, target_ng, source_well)
    check_inputs_to_volume_to_cherrypick_by_nano_grams!(minimum_volume, maximum_volume, target_ng, source_well)

    source_concentration = source_well.well_attribute.concentration.to_f
    source_volume        = source_well.well_attribute.measured_volume.to_f
    requested_volume     = [ source_volume, (target_ng.to_f/source_concentration).ceil ].min
    buffer_volume        = requested_volume < minimum_volume ? buffer_volume_required(minimum_volume, requested_volume) : 0.0
    requested_volume     = maximum_volume if requested_volume > maximum_volume

    well_attribute.current_volume   = minimum_volume
    well_attribute.requested_volume = minimum_volume
    well_attribute.picked_volume    = requested_volume
    well_attribute.buffer_volume    = buffer_volume

    requested_volume
  end

  def buffer_volume_required(minimum_volume, requested_volume)
    (minimum_volume*100 - requested_volume*100).to_i.to_f / 100
  end
  private :buffer_volume_required
end
