module Cherrypick::VolumeByNanoGramsPerMicroLitre
  def volume_to_cherrypick_by_nano_grams_per_micro_litre(volume_required,concentration_required,source_concentration)
    check_inputs_to_volume_to_cherrypick_by_nano_grams_per_micro_litre!(volume_required,concentration_required,source_concentration)
    
    set_concentration(concentration_required)
    set_current_volume(volume_required)
    set_requested_volume(volume_required)
    if source_concentration.blank? || source_concentration == 0.0 || concentration_required.blank? ||concentration_required ==0.0
      set_picked_volume(volume_required.ceil)
      set_buffer_volume(0.0)
      return volume_required.ceil
    else
      volume_to_pick = (volume_required*concentration_required)/(source_concentration)
      volume_to_pick= (((volume_to_pick).ceil).to_f)
      if volume_to_pick > volume_required
        volume_to_pick = volume_required
      end

      buffer_volume = (volume_required*100 - volume_to_pick*100)
      buffer_volume = (buffer_volume.to_i.to_f)/100
      set_buffer_volume(buffer_volume)
    end
    set_picked_volume(volume_to_pick)
    volume_to_pick
  end
  
  def check_inputs_to_volume_to_cherrypick_by_nano_grams_per_micro_litre!(volume_required,concentration_required,source_concentration)
    raise Cherrypick::VolumeError, "Volume required (#{volume_required.inspect}) is invalid for cherrypick by nano grams per micro litre"                      if volume_required.blank? || volume_required.to_f <= 0.0
    raise Cherrypick::ConcentrationError, "Concentration required (#{concentration_required.inspect}) is invalid for cherrypick by nano grams per micro litre" if concentration_required.blank? || concentration_required.to_f <= 0.0
    raise Cherrypick::ConcentrationError, "Source concentration (#{source_concentration.inspect}) is invalid for cherrypick by nano grams per micro litre"     if source_concentration.blank? || source_concentration.to_f <= 0.0
  end
  private :check_inputs_to_volume_to_cherrypick_by_nano_grams_per_micro_litre!
end

