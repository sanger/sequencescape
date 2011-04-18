module Cherrypick::VolumeByNanoGrams
  
  def check_inputs_to_volume_to_cherrypick_by_nano_grams!(minimum_volume, maximum_volume, target_ng, source_well)
    raise "Well not found" if source_well.nil?
    raise "Invalid volumes" if minimum_volume.blank? || minimum_volume <= 0.0 || maximum_volume.blank? || maximum_volume <= 0.0
    raise "Invalid target nano grams" if target_ng.blank? || target_ng <= 0.0
    source_concentration = source_well.well_attribute.concentration
    source_volume = source_well.well_attribute.measured_volume
    raise "Missing measured volume for Well #{source_well.id}" if source_volume.blank? || source_volume <= 0.0
    raise "Missing measured concentration for Well #{source_well.id}" if source_concentration.blank? || source_concentration <= 0.0 
    
    nil
  end
  
  def volume_to_cherrypick_by_nano_grams(minimum_volume, maximum_volume, target_ng, source_well)
    check_inputs_to_volume_to_cherrypick_by_nano_grams!(minimum_volume, maximum_volume, target_ng, source_well)
    
    source_concentration = source_well.well_attribute.concentration.to_f
    source_volume = source_well.well_attribute.measured_volume.to_f
    
    target_volume = (target_ng.to_f/source_concentration).ceil
    requested_volume = (target_volume <= source_volume)  ? target_volume : source_volume
    set_buffer_required(requested_volume, minimum_volume)
    
    if requested_volume > maximum_volume
      requested_volume = maximum_volume 
    end
    
    set_current_volume(minimum_volume)
    set_requested_volume(minimum_volume)
    set_picked_volume(requested_volume)
    
    requested_volume
  end
  
end

