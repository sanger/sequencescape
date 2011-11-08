module Cherrypick::VolumeByMicroLitre
  def volume_to_cherrypick_by_micro_litre(volume_required)
    check_inputs_to_volume_to_cherrypick_by_micro_litre!(volume_required)

    set_current_volume(volume_required)
    set_requested_volume(volume_required)
    
    volume_to_pick= (((volume_required).ceil).to_f)
    set_buffer_volume(0)
    set_picked_volume(volume_to_pick)
    
    volume_to_pick
  end
  
  def check_inputs_to_volume_to_cherrypick_by_micro_litre!(volume_required)
    raise Cherrypick::VolumeError, "Volume required (#{volume_required.inspect}) is invalid for cherrypicking by micro litre" if volume_required.blank? || volume_required.to_f <= 0.0
  end
  private :check_inputs_to_volume_to_cherrypick_by_micro_litre!
end

